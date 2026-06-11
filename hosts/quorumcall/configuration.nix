##################################
#                                #
#        QuorumCall Server       #
#   SSH access + QuorumCall TTY  #
#                                #
##################################
{lib, ...}: let
  import_users = ["server"];
  machine_type = "VM";
  machine_uuid = "Small";
in {
  calamoose.enableSecrets = false;

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["quorumcall"];};
    })
  ];

  networking.hostName = "quorumcall";

  services.greetd.enable = lib.mkForce false;
}
