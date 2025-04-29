###################################
#                                 #
#          HOST TEMPLATE          #
#                                 #
###################################
{...}: let
  hostname = builtins.baseNameOf (toString ./.);
  users = [
    # Default User (name will be override to "hub")
    ""

    # Other users
    ""
  ];

  machine_type = "Workstation | VM";
  machine_uuid = "TRX50-SAGE";
in {
  imports = [
    # Hardware Config

    # Common Core Config
    (import ../_core/configuration.nix {
      users_list = users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = hostname;
}
