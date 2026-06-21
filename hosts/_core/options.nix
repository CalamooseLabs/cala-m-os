{
  lib,
  config,
  ...
}: {
  options.calamoose.enableSecrets = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to load agenix secrets on this host.";
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
}
