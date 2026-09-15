##################################
#                                #
#   Hetzner dedicated (AX-series) #
#   TCI public fleet host         #
#                                #
##################################
{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];
}
