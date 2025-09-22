##################################
#                                #
#       Plex Media Server        #
#                                #
##################################
{config, ...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "Medium";

  caddyConfig = {
    "localhost:32400" = {
      aliases = ["plex.yourdomain.com"];
    };
  };

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
    (import ../../services/caddy/default.nix {
      caddyConfig = caddyConfig;
      tokenPath = tokenPath;
    })
  ];

  networking.hostName = "media";

  services.plex = {
    enable = true;
    openFirewall = true;
  };
}
