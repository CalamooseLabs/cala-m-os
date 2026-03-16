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
    ../../modules/amd-cpu/configuration.nix
  ];

  hardware.nvidia.prime = {
    offload.enable = true;

    nvidiaBusId = "PCI:001:0:0";
    amdgpuBusId = "PCI:014:0:0";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
