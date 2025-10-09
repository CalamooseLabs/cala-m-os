##################################
#                                #
#   Torrent Management Server    #
#                                #
##################################
{...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "Small";
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
        "radarr.calamooselabs.com" = "localhost:7878";
        "sonarr.calamooselabs.com" = "localhost:8989";
        "prowlarr.calamooselabs.com" = "localhost:9696";
        "qbit.calamooselabs.com" = "localhost:8080";
      };
    })
  ];

  networking.hostName = "torrent";

  services.radarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        urlbase = "localhost";
        port = 7878;
        bindaddress = "*";
      };
    };
  };

  fileSystems."/mnt/backup/radarr" = {
    device = "nas.calamos.family:/mnt/Media Library/Backups/Radarr";
    fsType = "nfs";
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        urlbase = "localhost";
        port = 8989;
        bindaddress = "*";
      };
    };
  };

  fileSystems."/mnt/backup/sonarr" = {
    device = "nas.calamos.family:/mnt/Media Library/Backups/Sonarr";
    fsType = "nfs";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        urlbase = "localhost";
        port = 9696;
        bindaddress = "*";
      };
    };
  };

  fileSystems."/mnt/backup/Prowlarr" = {
    device = "nas.calamos.family:/mnt/Media Library/Backups/Prowlarr";
    fsType = "nfs";
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    serverConfig = {
      LegalNotice.Accepted = true;
      Preferences = {
        General.Locale = "en";
      };
    };
    webuiPort = 8080;
  };
}
