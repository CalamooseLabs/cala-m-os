# tci-server — The Cobblemon Initiative dedicated-server FLEET on a headless box.
#
# This is a THIN wrapper, not a reimplementation. The fleet itself — hub +
# warden + on-demand per-player `tci-server@<player>` template instances, native
# Minecraft /transfer routing (no proxy), the soul-link event bus, co-op groups,
# world backups and the firewall — ships as `services.tci-server` from the mod
# repo's own NixOS module (github:The-Company-Inc-Nerds/the-cobblemon-initiative
# → nix/tci-server.nix; see that module's header for the full model). Here we
# only:
#   1. import it (the server bundle it runs sits at /srv/tci/bundle: deployed
#      by hand, or built on the box by services.tci-server.bundleBuild),
#   2. give every dynamic INSTANCE Aikar's G1GC flags for Java 21 — the module's
#      ExecStart is just `-Xmx<mem>` + jvmOpts, and the hub takes NO jvmOpts, so
#      the instance -Xms we add here can never exceed the hub's smaller -Xmx —
#      heap PINNED by default, one switch to unpin it
#      (calamoose.tciServer.pinHeap, below), and
#   3. strip the box to a headless server + tune the kernel so ~everything is
#      allocated to the JVMs.
#
# Each host that runs a fleet sets `services.tci-server` itself (public-coop vs
# soul-link differ there, and in the heap switch); this module carries the
# shared box policy and is INERT unless the fleet is enabled.
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
  # This is the PINNED list (calamoose.tciServer.pinHeap = true, the default):
  # leave it byte for byte — its order is a pinned fleet's ExecStart.
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

  # The UNPINNED list (pinHeap = false): the same G1 tuning minus the two flags
  # that commit the whole heap at start, plus a periodic collection every two
  # minutes on a JVM that ran none — the one that lets an idle world's heap
  # shrink and go back to the OS. Derived from the pinned list (the upstream
  # module builds cagelocke.standby.jvmOpts the same way) so the tuning can
  # never drift between the two.
  commitsHeapAtStart = f: lib.hasPrefix "-Xms" f || f == "-XX:+AlwaysPreTouch";
  unpinnedFlags = mem:
    lib.filter (f: !(commitsHeapAtStart f)) (aikarFlags mem)
    ++ ["-XX:G1PeriodicGCInterval=120000"];

  instanceFlags = mem:
    if config.calamoose.tciServer.pinHeap
    then aikarFlags mem
    else unpinnedFlags mem;
in {
  imports = [inputs.cobblemon-initiative.nixosModules.tci-server];

  options.calamoose.tciServer.pinHeap = lib.mkOption {
    type = lib.types.bool;
    default = true;
    example = false;
    description = ''
      Heap policy of every dynamic fleet instance — which Aikar flag list this
      module feeds services.tci-server.instanceDefaults.jvmOpts.

      true (default): PINNED. `-Xms` equals the instance's `-Xmx` and
      `-XX:+AlwaysPreTouch` is set, so each world commits and faults in its
      whole heap when it starts: no page-fault stalls mid-tick, and the RAM
      budget is plainly instanceDefaults.memory × maxActive. Right for a fleet
      sized to fit its box (tci-private).

      false: UNPINNED. Both flags are dropped and
      `-XX:G1PeriodicGCInterval=120000` is added: a world's heap grows only as
      far as it has needed, and an idle one runs a periodic collection that
      hands memory back to the OS. For a box that ALLOWS more worlds at once
      than their `-Xmx` sum fits in RAM (tci-cloud: ten 4G worlds on 32 GB).
      It only makes the overcommit survivable, it does not make it fit — pair
      it with services.tci-server.warden.minFreeMemoryMB, which stops new
      worlds starting while memory is short, and a larger zramSwap.

      A host that sets services.tci-server.instanceDefaults.jvmOpts itself
      replaces the whole list, and this switch then does nothing. The flags
      are read at launch: a running world keeps the ones it started with.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Aikar G1 flags for every dynamic instance (mkDefault — a host may override
    # wholesale), pinned or unpinned per calamoose.tciServer.pinHeap. Only
    # instances receive these: the hub unit is built with no jvmOpts, so it
    # never gets the instance -Xms (which would exceed its -Xmx).
    services.tci-server.instanceDefaults.jvmOpts =
      lib.mkDefault (instanceFlags cfg.instanceDefaults.memory);

    # ---- headless: this box is a JVM fleet, nothing graphical runs on it ----
    # _core turns greetd + plymouth on by default; force them off. Console access
    # is over SSH / the provider's rescue console, where a plain getty beats a
    # greeter-runs-bash session and a framebuffer splash.
    services.greetd.enable = lib.mkForce false;
    boot.plymouth.enable = lib.mkForce false;

    # ---- fleet kernel policy (sysctl keys MUST be quoted strings) ----
    boot.kernel.sysctl = {
      # Keep instance heaps resident (pre-touched or not); don't page them out.
      # Swap is the overflow, never a working area.
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

    # The awake instances own the RAM: pinned heaps commit all of theirs up
    # front, unpinned ones grow into whatever is left. A RAM-backed /tmp would
    # compete for it either way. _core sets useTmpfs on unconditionally, so
    # override it off on a fleet box (disk-backed /tmp).
    boot.tmp.useTmpfs = lib.mkForce false;
    boot.tmp.cleanOnBoot = true;

    # Compressed-RAM swap: a safety margin under low swappiness that beats paging
    # a live heap to disk. Pinned heaps shouldn't normally reach it; a host that
    # unpins them to overcommit (pinHeap = false) raises memoryPercent, because
    # there zram IS the designed overflow.
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
