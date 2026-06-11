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

  networking.networkmanager.enable = lib.mkForce false;

  networking = {
    interfaces.eno2 = {
      ipv4.addresses = [
        {
          address = "10.1.10.40";
          prefixLength = 26;
        }
      ];
    };
    defaultGateway = {
      address = "10.1.10.1";
      interface = "enp88s0";
    };
    nameservers = ["10.1.10.1"];
  };

  networking.hostName = "livedata";
}
