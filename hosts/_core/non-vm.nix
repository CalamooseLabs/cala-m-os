{
  cala-m-os,
  lib,
  ...
}: {
  # Allow unfree
  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = {system = "x86_64-linux";};
  };

  nix.settings.auto-optimise-store = true;

  # Allow any wheel user to change configuration
  system.activationScripts.setPermissions = ''
    # Set ownership to root:wheel
    chown -R ${cala-m-os.globals.defaultUser}:${cala-m-os.globals.adminGroup} /etc/nixos

    # Set directory permissions to 775
    find /etc/nixos -type d -exec chmod 775 {} +

    # Set file permissions to 664
    find /etc/nixos -type f -exec chmod 664 {} +
  '';

  # Enable Network Manager
  networking.networkmanager.enable = lib.mkDefault true;
  # TODO:
  # These next steps should only happen on certain hosts (IE devbox but not htpc)
  # These will be moved to a oneshot on non-vm
  # Preftech, gpg keys, ssh keys
}
