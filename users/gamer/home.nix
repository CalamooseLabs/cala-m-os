{...}: {
  pkgs,
  cala-m-os,
  ...
}: {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  system.activationScripts.setGamesPermissions = ''
    # Set ownership to root:wheel
    chown -R ${cala-m-os.globalDefaultUser}:${cala-m-os.globalAdminGroup} /mnt/games

    # Set directory permissions to 775
    find /etc/nixos -type d -exec chmod 775 {} +

    # Set file permissions to 664
    find /etc/nixos -type f -exec chmod 664 {} +
  '';
}
