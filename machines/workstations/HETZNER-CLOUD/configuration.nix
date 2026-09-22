##################################
#                                #
#   Hetzner Cloud (US, CCX)      #
#   TCI cloud fleet host         #
#                                #
##################################
{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];
}
