##################################
#                                #
#       Plex Media Server        #
#                                #
##################################
{cala-m-os, ...}: let
  import_users = ["server"];

  machine_type = "VM";
  # Medium (6 vCPU / 16 GB) — headroom for any CPU-bound Plex transcode steps
  # (HDR tone-mapping, image-subtitle burn-in) alongside B50 HW decode/encode.
  machine_uuid = "Medium";
in {
  calamoose.version = "0.9.0-beta";

  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["plex"];};
    })

    # Caddy SSL
    ../../services/caddy
  ];

  services.cala-caddy = {
    enable = true;
    reverseProxies = {
      "plex.${cala-m-os.fqdn}" = "localhost:32400";
    };
  };
}
