##################################
#                                #
#        OpenReturn Server       #
#      Minisforum MS-01          #
#   SSH access + OpenReturn TTY  #
#                                #
##################################
{...}: let
  import_users = ["server"];
  machine_type = "Workstation";
  machine_uuid = "MS-01";
in {
  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["openreturn"];};
    })
  ];

  networking.hostName = "openreturn";
}
