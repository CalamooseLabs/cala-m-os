##################################
#                                #
#         Lab Powerhouse         #
#                                #
#     Used for the Following:    #
#     - Playground for Testing   #
#     - Virtualization           #
#                                #
##################################
{...}: let
  users = ["virt"];

  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";
in {
  imports = [
    # Hardware Config
    ./modules/virt-manager

    # Common Core Config
    (import ../_core/configuration.nix {
      users_list = users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "lab";
}
