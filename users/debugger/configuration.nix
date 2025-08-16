{username, ...}: {
  config,
  pkgs,
  ...
}: {
  users.users."${username}" = {
    extraGroups = ["wheel" "networkmanager" "scanner" "lp" "disk" "plugdev"];
  };

  services.udev.extraRules = ''
    # Raspberry Pi usbboot
    SUBSYSTEM=="usb", ATTR{idVendor}=="0a5c", ATTR{idProduct}=="2763", GROUP="plugdev", MODE="0664"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0a5c", ATTR{idProduct}=="2764", GROUP="plugdev", MODE="0664"
  '';

  security.sudo.extraRules = [
    {
      users = ["${username}"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  home-manager = {
    users."${username}" = {
      imports = [
      ];
    };
  };

  fileSystems."/mnt/backups" = {
    device = "nas.calamos.family:/mnt/Media Library/Backups";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
    ];
  };

  environment.systemPackages = [pkgs.cifs-utils];
  fileSystems."/mnt/nkc" = {
    device = "//10.50.1.1/Data";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "credentials=${config.age.secrets.work_credentials.path}"
    ];
  };
}
