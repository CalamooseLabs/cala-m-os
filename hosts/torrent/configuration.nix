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
  calamoose.version = "0.9.0-beta";

  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["radarr" "sonarr" "prowlarr" "qbittorrent"];};
    })

    # Caddy SSL
    ../../services/caddy
  ];

  services.cala-caddy = {
    enable = true;
    reverseProxies = {
      "radarr.${cala-m-os.fqdn}" = "localhost:7878";
      "sonarr.${cala-m-os.fqdn}" = "localhost:8989";
      "prowlarr.${cala-m-os.fqdn}" = "localhost:9696";
      "qbit.${cala-m-os.fqdn}" = "10.200.200.2:8080";
    };
  };

  # Media library NFS shares (mirrors the Plex/media host) so the *arr suite can
  # import completed downloads into the library. The per-service backup shares
  # are mounted by the radarr/sonarr/prowlarr modules.
  boot.supportedFilesystems = ["nfs"];

  fileSystems."/media/movies" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.media.movies}";
    fsType = "nfs";
  };

  fileSystems."/media/tv-shows" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.media.tv-shows}";
    fsType = "nfs";
  };

  systemd.tmpfiles.rules = [
    "d /data/qbit 0755 qbittorrent qbittorrent -"
    "d /data/qbit/downloads 0755 qbittorrent qbittorrent -"
    "d /data/qbit/incomplete 0755 qbittorrent qbittorrent -"
  ];

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
