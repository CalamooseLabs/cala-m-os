##################################
#                                #
#       Torrents & *Arrs         #
#                                #
##################################
{...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "small";
in {
  imports = [
    # Common Core Config
    (import ../_core/configuration.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "torrent";
}
