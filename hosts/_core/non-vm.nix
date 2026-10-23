{
  cala-m-os,
  lib,
  ...
}: {
  # Allow unfree
  nixpkgs.config.allowUnfree = true;

  # Each machine's hardware-configuration.nix owns the platform (x86_64
  # everywhere except HETZNER-CAX, which is aarch64). This is only the
  # lowest-priority fallback, so hostPlatform is always defined; the beta pin
  # (options.nix) reads it. It must stay below the machines' mkDefault.
  nixpkgs.hostPlatform = lib.mkOptionDefault "x86_64-linux";

  nix.settings.auto-optimise-store = true;

  # Allow any wheel user to change configuration. Skipped when there is no
  # checkout: hosts deployed remotely (nixos-anywhere / --target-host, e.g.
  # webhost) have no /etc/nixos, and a failing snippet fails the whole switch.
  system.activationScripts.setPermissions = ''
    if [ -d /etc/nixos ]; then
      # Set ownership to root:wheel
      chown -R ${cala-m-os.globals.defaultUser}:${cala-m-os.globals.adminGroup} /etc/nixos

      # Set directory permissions to 775
      find /etc/nixos -type d -exec chmod 775 {} +

      # Set file permissions to 664
      find /etc/nixos -type f -exec chmod 664 {} +
    fi
  '';

  # Enable Network Manager
  networking.networkmanager.enable = lib.mkDefault true;
}
