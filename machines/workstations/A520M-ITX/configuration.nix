##################################
#                                #
#       ASRock A520M-ITX/ac      #
#        AMD Ryzen 5 5600        #
#         32GB DDR4 2666         #
#       Gigabyte RTX4070 TI      #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
