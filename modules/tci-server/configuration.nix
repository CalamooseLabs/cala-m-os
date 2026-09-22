# tci-server — The Cobblemon Initiative dedicated-server FLEET on a headless box.
#
# This is a THIN wrapper, not a reimplementation. The fleet itself — hub +
# warden + on-demand per-player `tci-server@<player>` template instances, native
# Minecraft /transfer routing (no proxy), the soul-link event bus, co-op groups,
# world backups and the firewall — ships as `services.tci-server` from the mod
# repo's own NixOS module (github:The-Company-Inc-Nerds/the-cobblemon-initiative
# → nix/tci-server.nix; see that module's header for the full model). Here we
# only:
#   1. import it (fed the `build_mrpack.py --server` bundle at /srv/tci/bundle),
#   2. give every dynamic INSTANCE Aikar's G1GC flags for Java 21 — the module's
#      ExecStart is just `-Xmx<mem>` + jvmOpts, and the hub takes NO jvmOpts, so
#      the instance -Xms we add here can never exceed the hub's smaller -Xmx, and
#   3. strip the box to a headless server + tune the kernel so ~everything is
#      allocated to the JVMs.
#
# Each host that runs a fleet sets `services.tci-server` itself (public-coop vs
# soul-link differ only there); this module carries the shared box policy and is
# INERT unless the fleet is enabled.
#
# The upstream flake input is a PRIVATE repo — every host that consumes this
# module also enables "nix-github-token" so Nix can fetch it at eval time (see
# hosts/tci-cloud + hosts/tci-private).
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.tci-server;

  # Aikar's canonical G1GC flags for Java 21, standard (<12G heap) preset. Xms is
  # pinned equal to the instance Xmx so +AlwaysPreTouch faults in the whole heap
  # at start (no mid-tick page-fault stalls). `mem` is the module's -Xmx string.
  aikarFlags = mem: [
    "-Xms${mem}"
    "-XX:+UseG1GC"
    "-XX:+ParallelRefProcEnabled"
    "-XX:MaxGCPauseMillis=200"
    "-XX:+UnlockExperimentalVMOptions"
    "-XX:+DisableExplicitGC"
    "-XX:+AlwaysPreTouch"
    "-XX:G1NewSizePercent=30"
    "-XX:G1MaxNewSizePercent=40"
    "-XX:G1HeapRegionSize=8M"
    "-XX:G1ReservePercent=20"
    "-XX:G1HeapWastePercent=5"
    "-XX:G1MixedGCCountTarget=4"
    "-XX:InitiatingHeapOccupancyPercent=15"
    "-XX:G1MixedGCLiveThresholdPercent=90"
    "-XX:G1RSetUpdatingPauseTimePercent=5"
    "-XX:SurvivorRatio=32"
    "-XX:+PerfDisableSharedMem"
    "-XX:MaxTenuringThreshold=1"
    "-XX:+UseStringDeduplication"
  ];
in {
  imports = [inputs.cobblemon-initiative.nixosModules.tci-server];

  config = lib.mkIf cfg.enable {
    # Aikar G1 flags for every dynamic instance (mkDefault — a host may override
    # wholesale). Only instances receive these: the hub unit is built with no
    # jvmOpts, so it never gets the instance -Xms (which would exceed its -Xmx).
    services.tci-server.instanceDefaults.jvmOpts =
      lib.mkDefault (aikarFlags cfg.instanceDefaults.memory);

    # ---- headless: this box is a JVM fleet, nothing graphical runs on it ----
    # _core turns greetd + plymouth on by default; force them off. Console access
    # is over SSH / the provider's rescue console, where a plain getty beats a
    # greeter-runs-bash session and a framebuffer splash.
    services.greetd.enable = lib.mkForce false;
    boot.plymouth.enable = lib.mkForce false;

    # ---- fleet kernel policy (sysctl keys MUST be quoted strings) ----
    boot.kernel.sysctl = {
      # Keep AlwaysPreTouch'd instance heaps resident; don't page them out.
      "vm.swappiness" = lib.mkDefault 10;
      "vm.vfs_cache_pressure" = lib.mkDefault 50;
      # NOTE: vm.max_map_count (which heavily-modded MC needs raised) is left to
      # nixpkgs — nixos-unstable already defaults it to 1048576, above the 262144
      # modded-MC floor, so setting it here only conflicts and would lower it.
      # Many concurrent connections across the fleet + transfer churn.
      "net.core.somaxconn" = lib.mkDefault 8192;
      "net.core.netdev_max_backlog" = lib.mkDefault 16384;
      "net.ipv4.tcp_max_syn_backlog" = lib.mkDefault 8192;
    };

    # AlwaysPreTouch commits every awake instance's whole heap up front; a
    # RAM-backed /tmp would compete for that RAM. _core sets useTmpfs on
    # unconditionally, so override it off on a fleet box (disk-backed /tmp).
    boot.tmp.useTmpfs = lib.mkForce false;
    boot.tmp.cleanOnBoot = true;

    # Compressed-RAM swap: a safety margin under low swappiness that beats paging
    # a live heap to disk. Heaps shouldn't normally reach it.
    zramSwap = {
      enable = lib.mkDefault true;
      algorithm = "zstd";
      memoryPercent = lib.mkDefault 25;
    };

    # A long-running fleet must not let the journal eat the disk.
    services.journald.extraConfig = lib.mkDefault ''
      SystemMaxUse=512M
      SystemMaxFileSize=64M
      MaxRetentionSec=1week
    '';

    # Operator RCON client — each instance's RCON is localhost, game port +10000
    # (only bound when backups are enabled). `tci-server-reset` / `-retire` come
    # from the upstream module.
    environment.systemPackages = [pkgs.mcrcon];
  };
}
