###################################
#                                 #
#          HOST TEMPLATE          #
#                                 #
###################################
{...}: let
  hostname = baseNameOf (toString ./.);
  users = [
    # Default User (name will be override to "hub")
    ""

    # Other users
    ""
  ];

  machine_type = "Workstation | VM";
  machine_uuid = "MACHINEXXXX";
in {
  imports = [
    # Hardware Config

    # Common Core Config
    (import ../_core/default.nix {
      users_list = users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

  networking.hostName = hostname;
}
