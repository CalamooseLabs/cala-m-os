##################################
#                                #
#        Main Daily Laptop       #
#                                #
##################################
{inputs, ...}: let
  import_users = [
    # Default User
    "hub"

    # Other Users
    "virt"
  ];
in {
  imports = [
    # Hardware Config
    inputs.disko.nixosModules.disko
    ../../machines/workstations/TRX50-SAGE/configuration.nix

    # Common Core Config
    (import ../_core/configuration.nix {users_list = import_users;})
  ];

  networking.hostName = "lab";
}
