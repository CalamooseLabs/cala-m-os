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

  # Mellanox works out of the box on host
  boot.kernelModules = [
    # "mlx5_core"  # or mlx4_core depending on your card
    # "mlx5_ib"    # If using InfiniBand
    # VFIO for GPU passthrough
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];

  # Only blacklist NVIDIA GPU drivers
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "nouveau"
  ];

  # Bind only GPU to VFIO
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=10de:2705,10de:22bb" # Only GPU IDs
  ];
}
