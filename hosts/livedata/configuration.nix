##################################
#                                #
#        LiveData Server         #
#                                #
##################################
{...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "X-Small";
in {
  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["livedata"];};
    })
  ];

  networking.hostName = "livedata";
}
