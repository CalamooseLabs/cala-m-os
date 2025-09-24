##################################
#                                #
#       Plex Media Server        #
#                                #
##################################
{...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "Medium";
in {
  imports = [
    ./secrets

    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })

    # Caddy SSL
    (import ../../services/caddy/default.nix {
      domain = "plex.calamooselabs.com";
      target = "localhost:32400";
    })
  ];

  networking.hostName = "media";

  services.plex = {
    enable = true;
    openFirewall = true;
  };
}
