##################################
#                                #
#       Plex Media Server        #
#                                #
##################################
{cala-m-os, ...}: let
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
        "plex.${cala-m-os.fqdn}" = "localhost:32400";
      };
    })
  ];

  services.plex = {
    enable = true;
    openFirewall = true;
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/media/movies" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.media.movies}";
    fsType = "nfs";
  };

  fileSystems."/media/tv-shows" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.media.tv-shows}";
    fsType = "nfs";
  };

  fileSystems."/mnt/backup" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.backup.plex}";
    fsType = "nfs";
  };
}
