##################################
#                                #
#        LiveData Server         #
#       Minisforum MS-01         #
#                                #
##################################
{
  lib,
  initialInstallMode,
  ...
}: let
  import_users = ["server"];
  machine_type = "Workstation";
  machine_uuid = "MS-01";
in {
  calamoose.enableSecrets = false;

  imports =
    [
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
        extra_user_modules = {};
      })
    ]
    ++ lib.optional (!initialInstallMode) ./vms.nix;

  networking.hostName = "livedata";
}
