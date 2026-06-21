##################################
#                                #
#   Torrent Management Server    #
#                                #
##################################
{
  cala-m-os,
  lib,
  config,
  ...
}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "X-Small";

  # Media storage layout — see calamoose.hardlinkLayout. true: downloads and the
  # library share one NFS mount so *arr imports hardlink instead of copying.
  hardlink = config.calamoose.hardlinkLayout;
  dataRoot = "/data";
in {
  calamoose.version = "0.9.0-beta";

  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["radarr" "sonarr" "prowlarr" "qbittorrent" "qbittorrent-scheduler"];};
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

  boot.supportedFilesystems = ["nfs"];

  # Media/download NFS shares for the *arr suite. (Per-service backup shares are
  # mounted by the radarr/sonarr/prowlarr modules.)
  fileSystems =
    if hardlink
    then {
      # One mount of the library root → downloads and library share a
      # filesystem, so *arr imports are instant hardlinks (zero data copied).
      # nofail so a not-yet-ready NAS can't wedge boot; qBittorrent/*arr wait
      # for the mount via RequiresMountsFor below.
      "${dataRoot}" = {
        device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.media.root}";
        fsType = "nfs";
        options = ["nofail"];
      };
    }
    else {
      # Library mounted per folder for *arr to import into; downloads are local,
      # so a completed import copies across filesystems (the egressRateLimit on
      # this VM keeps that copy from saturating the NAS).
      "/media/movies" = {
        device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.media.movies}";
        fsType = "nfs";
      };
      "/media/tv-shows" = {
        device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.media.tv-shows}";
        fsType = "nfs";
      };
    };

  # Local download dirs are only needed in copy mode; in hardlink mode they live
  # on the NFS share (pre-created on the NAS / by qBittorrent's preStart).
  systemd.tmpfiles.rules =
    lib.optionals (!hardlink) [
      "d /data/qbit 0755 qbittorrent qbittorrent -"
      "d /data/qbit/downloads 0755 qbittorrent qbittorrent -"
      "d /data/qbit/incomplete 0755 qbittorrent qbittorrent -"
    ];

  # In hardlink mode, anything that touches the shared mount must start after it.
  # Without this, qBittorrent's preStart `mkdir -p` would create the download dir
  # on the local root and mask the NFS mount.
  systemd.services = lib.mkIf hardlink {
    qbittorrent.unitConfig.RequiresMountsFor = dataRoot;
    radarr.unitConfig.RequiresMountsFor = dataRoot;
    sonarr.unitConfig.RequiresMountsFor = dataRoot;
  };

  services.qbittorrent-vpn = {
    enable = true;

    wireguardConfigFile = "/run/hostsecrets/proton-vpn.conf";
    qbittorrentPasswordFile = "/run/hostsecrets/qbit-password";

    webUI = {
      port = 8080;
      username = "admin";
    };

    downloads =
      if hardlink
      then {
        # On the shared NFS mount so completed files hardlink into the library.
        # Incomplete is on the same fs → completion is an instant move, not a copy.
        path = "${dataRoot}/Downloads";
        incompletePath = "${dataRoot}/Downloads/incomplete";
      }
      else {
        path = "/data/qbit/downloads";
        incompletePath = "/data/qbit/incomplete";
      };

    seedingLimits = {
      maxRatio = 2.0;
      maxSeedingDays = 45;
      # When ratio/time is hit, drop qBittorrent's own copy of the file. With
      # the hardlink layout the library keeps its own name for the same bytes,
      # so the show survives in the library while qBit stops seeding and tidies
      # up its Downloads/ entry.
      actionOnLimit = "remove-with-files";
      enableAutoDelete = false;
    };

    speedLimits = {
      globalUpload = 102400; # 100 MB/s
      globalDownload = 1024000; # 1000 MB/s
    };
  };

  # Media import layout (hardlink, staged ON). Requires the NAS to export the
  # library root (nfs.media.root) with a Downloads/ dir writable by the torrent
  # VM (set Mapall on the NFS share), and the *arr root folders pointed at
  # /data. With this on, *arr imports are instant hardlinks and the import copy
  # disappears. Set false to fall back to local downloads + per-folder mounts.
  calamoose.hardlinkLayout = true;

  # Imported (via the server profile) but off. Flip enable to true to throttle
  # qBittorrent to the alternative limits during prime streaming hours, so peer
  # traffic backs off and *arr imports are less likely to contend with Plex at
  # the NAS. Tune the window/limits as needed (times are America/Denver).
  services.qbittorrent-scheduler = {
    enable = false;
    from = "17:00";
    to = "23:00";
    download = 10240; # 10 MB/s during the window
    upload = 5120; # 5 MB/s during the window
  };
}
