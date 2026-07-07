{
  lib,
  config,
  ...
}: {
  options.calamoose.enableSecrets = lib.mkOption {
    # Tri-state, backward-compatible:
    #   false            -> no secrets loaded
    #   true | "offline" -> agenix        (decrypt to /run/agenix)        [default]
    #   "online"         -> Proton Pass   (decrypt to /run/proton-secrets)
    # The bool form is retained so existing `= false` / `= true` hosts still parse.
    type = lib.types.either lib.types.bool (lib.types.enum ["offline" "online"]);
    default = "offline";
    example = "online";
    description = ''
      Secrets backend for this host. `false` disables secrets; `true`/"offline"
      uses agenix (Yubikey/age, offline); "online" uses the Proton Pass CLI
      (services.proton-secrets) to fetch secrets at activation.
    '';
  };

  # Resolved, read-only backend — the single source of truth for every consumer.
  options.calamoose._secretsBackend = lib.mkOption {
    type = lib.types.enum ["none" "agenix" "proton-pass"];
    readOnly = true;
    internal = true;
    description = "Resolved secrets backend, computed from enableSecrets. Do not set.";
  };

  # Convenience bool for `mkIf` gates (enableSecrets may be a string, which mkIf rejects).
  options.calamoose._secretsEnabled = lib.mkOption {
    type = lib.types.bool;
    readOnly = true;
    internal = true;
    description = "True when any secrets backend is active. Use in mkIf. Do not set.";
  };

  options.calamoose.version = lib.mkOption {
    type = lib.types.str;
    default = "0.0.1-beta";
    description = ''
      Human-set version mark for this host. The installer prints it at the start
      and end of an install, and it is appended to the system label so it shows in
      `nixos-version` and the systemd-boot menu entry.
    '';
  };

  options.calamoose.install.wipeAllDisks = lib.mkOption {
    type = lib.types.bool;
    default = false;
    example = true;
    description = ''
      Install-time disk policy read by `install-cala-m-os`. When true, disko runs
      in destroy,format,mount mode with --yes-wipe-all-disks — an unattended full
      wipe of EVERY disk in this host's disko config. Leave false (default) for
      machines that dual-boot or own only some disks: the installer then refuses
      to auto-partition rather than blowing them away. Set true only for boxes
      NixOS fully owns (e.g. broadcast/TRX50-SAGE).
    '';
  };

  options.calamoose.hardlinkLayout = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Media import layout for hosts running qBittorrent + the *arr suite.

      false (default): qBittorrent downloads to local disk and the library is
      NFS-mounted per folder, so an *arr import copies the file across
      filesystems into the NAS.

      true: a single NFS mount of the library root (nfs.media.root) holds both
      downloads and the library, so *arr imports become instant hardlinks (no
      data copied). Requires the NAS to export the library root with a
      Downloads/ dir writable by the qbittorrent uid, and the *arr root folders
      / remote-path mappings reconfigured to the shared mount.
    '';
  };

  # Surface the host version in `nixos-version` / the boot menu entry.
  config.system.nixos.tags = ["cala-${config.calamoose.version}"];

  # Normalize the tri-state flag into the resolved backend + convenience bool.
  config.calamoose._secretsBackend = let
    v = config.calamoose.enableSecrets;
  in
    if v == false
    then "none"
    else if (v == true || v == "offline")
    then "agenix"
    else "proton-pass"; # v == "online"

  config.calamoose._secretsEnabled = config.calamoose._secretsBackend != "none";
}
