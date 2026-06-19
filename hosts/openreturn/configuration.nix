##################################
#                                #
#        OpenReturn Server       #
#   SSH access + OpenReturn TTY  #
#                                #
##################################
{lib, ...}: let
  import_users = ["server"];
  machine_type = "VM";
  machine_uuid = "Small";
in {
  calamoose.enableSecrets = false;
  calamoose.version = "0.1.0-alpha";

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["openreturn"];};
    })
  ];

  networking.hostName = "openreturn";

  services.greetd.enable = lib.mkForce false;
}
