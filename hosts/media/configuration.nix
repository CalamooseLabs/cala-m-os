##################################
#                                #
#       Plex Media Server        #
#                                #
##################################
{config, ...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "Medium";

  tokenPath = config.age.secrets.plex-cloudflare-token.path;
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
    (import ../../services/certs/default.nix {
      domain = "plex.calamooselabs.com";
      tokenPath = tokenPath;
      target = "localhost:32400";
    })
  ];

  networking.hostName = "media";

  services.plex = {
    enable = true;
    openFirewall = true;
  };
}
