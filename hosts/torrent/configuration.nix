##################################
#                                #
#   Torrent Management Server    #
#                                #
##################################
{cala-m-os, ...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "X-Small";
in {
  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })

    # Caddy SSL
    (import ../../services/caddy/default.nix {
      reverse_proxies = {
        "radarr.${cala-m-os.fqdn}" = "localhost:7878";
        "sonarr.${cala-m-os.fqdn}" = "localhost:8989";
        "prowlarr.${cala-m-os.fqdn}" = "localhost:9696";
        "qbit.${cala-m-os.fqdn}" = "localhost:8080";
      };
    })

    # Import QBittorrent
    ../../modules/qbittorrent/configuration.nix
  ];

  networking.hostName = "torrent";

  services.radarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 7878;
        bindaddress = "*";
      };
    };
  };

  fileSystems."/mnt/backups/radarr" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.backup.radarr}";
    fsType = "nfs";
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 8989;
        bindaddress = "*";
      };
    };
  };

  fileSystems."/mnt/backups/sonarr" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.backup.sonarr}";
    fsType = "nfs";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 9696;
        bindaddress = "*";
      };
    };
  };

  fileSystems."/mnt/backups/prowlarr" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.backup.prowlarr}";
    fsType = "nfs";
  };

  services.qbittorrent-vpn = {
    enable = true;

    wireguardConfigFile = "/run/hostsecrets/proton-vpn.conf";
    qbittorrentPasswordFile = "/run/hostsecrets/qbit-password";

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
      maxSeedingDays = 45;
      actionOnLimit = "remove";
      enableAutoDelete = false;
    };

    speedLimits = {
      globalUpload = 102400; # 100 MB/s
      globalDownload = 1024000; # 1000 MB/s
    };
  };
}
