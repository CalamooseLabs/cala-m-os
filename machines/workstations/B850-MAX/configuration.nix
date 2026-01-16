##################################
#                                #
#      MSI B850 Tomahawk Max     #
#      AMD Ryzen 7 9800x3D       #
#         32GB DDR5 6400         #
#             RTX5090            #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix

    # Modules
    ../../modules/nvidia-gpu/configuration.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
