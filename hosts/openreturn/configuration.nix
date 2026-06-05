##################################
#                                #
#        OpenReturn Server       #
#      Minisforum MS-01          #
#   SSH access + OpenReturn TTY  #
#                                #
##################################
{
  lib,
  cala-m-os,
  ...
}: let
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

  # OpenReturn runs directly on TTY via autologin
  services.greetd.settings = {
    initial_session = {
      command = "openreturn";
      user = cala-m-os.globals.defaultUser;
    };
    default_session.command = lib.mkForce "sudo openreturn --host 0.0.0.0 --port 80";
  };

  services.openreturn.enable = lib.mkForce false;
}
