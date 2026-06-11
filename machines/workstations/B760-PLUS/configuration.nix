##################################
#                                #
#       Minisforum MS-02         #
#      NVIDIA RTX 5090FE         #
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
