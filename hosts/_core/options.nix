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

  # Surface the host version in `nixos-version` / the boot menu entry.
  config.system.nixos.tags = ["cala-${config.calamoose.version}"];
}
