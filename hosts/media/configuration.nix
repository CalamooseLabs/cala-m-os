##################################
#                                #
#       Plex Media Server        #
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
        "plex.calamooselabs.com" = "localhost:32400";
      };
    })
  ];

  networking.hostName = "media";

  services.plex = {
    enable = true;
    openFirewall = true;
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/media/movies" = {
    device = "nas.calamos.family:/mnt/Media Library/Movies";
    fsType = "nfs";
  };

  fileSystems."/media/tv-shows" = {
    device = "nas.calamos.family:/mnt/Media Library/TV-Shows";
    fsType = "nfs";
  };

  fileSystems."/mnt/backup" = {
    device = "nas.calamos.family:/mnt/Media Library/Backups/Plex";
    fsType = "nfs";
  };
}
