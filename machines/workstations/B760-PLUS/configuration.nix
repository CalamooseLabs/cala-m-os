##################################
#                                #
#     ASUS PRIME B760-PLUS       #
#      NVIDIA RTX 5090 FE        #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nvidia-gpu/configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
