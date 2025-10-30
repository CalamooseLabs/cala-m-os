{username, ...}: {
  config,
  pkgs,
  ...
}: {
  users.users."${username}" = {
    extraGroups = [
      "wheel"
      "networkmanager"
      "scanner"
      "lp"
      "disk"
      "plugdev"
      "dialout"
    ];
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
      "credentials=${config.age.secrets.work_credentials.path}"
    ];
  };

  services.qbittorrent-vpn = {
    enable = true;

    # Path to WireGuard config with private key included
    wireguardConfigFile = config.age.secrets."proton_vpn.conf".path;

    # Path to qBittorrent password hash
    qbittorrentPasswordFile = config.age.secrets.admin_password.path;

    webUI = {
      port = 8080;
      username = "admin";
    };

    downloads = {
      path = "/data/qbit/downloads";
      incompletePath = "/data/qbit/incomplete";
    };

    seedingLimits = {
      maxRatio = 2.0;
      maxSeedingDays = 7;
      actionOnLimit = "remove";
      enableAutoDelete = false;
    };

    speedLimits = {
      globalUpload = 5120; # 5 MB/s
      globalDownload = 10240; # 10 MB/s
    };
  };
}
