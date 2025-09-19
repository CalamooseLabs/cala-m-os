{
  lib,
  cala-m-os,
  ...
}: {
  # Allow unfree
  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = {system = "x86_64-linux";};
  };

  # Login Service
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = lib.mkForce "${cala-m-os.globalDefaultUser}";
      };
    };
  };

  # Allow any wheel user to change configuration
  system.activationScripts.setPermissions = ''
    # Set ownership to root:wheel
    chown -R ${cala-m-os.globalDefaultUser}:${cala-m-os.globalAdminGroup} /etc/nixos

    # Set directory permissions to 775
    find /etc/nixos -type d -exec chmod 775 {} +

    # Set file permissions to 664
    find /etc/nixos -type f -exec chmod 664 {} +
  '';
}
