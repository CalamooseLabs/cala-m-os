{username, ...}: {
  config,
  pkgs,
  ...
}: {
  users.users."${username}" = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.admin_hash.path;
    extraGroups = ["wheel" "networkmanager" "scanner" "lp"];
  };

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
      "credentials=${config.sops.secrets.work_credentials.path}"
    ];
  };
}
