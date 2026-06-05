##################################
#                                #
#      Minisforum MS-02          #
#     NVIDIA RTX Pro 4000        #
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
