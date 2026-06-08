##################################
#                                #
#        LiveData Server         #
#       Minisforum MS-01         #
#                                #
##################################
{...}: let
  import_users = ["server"];
  machine_type = "Workstation";
  machine_uuid = "MS-01";
  enable_secrets = false;
in {
  calamoose.enableSecrets = enable_secrets;

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

  networking.hostName = "livedata";
}
