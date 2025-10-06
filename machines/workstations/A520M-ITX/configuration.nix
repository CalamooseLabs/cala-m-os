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

  boot.kernelModules = [
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
  # -----------------------------------------------------------------
  # Core graphics stack – required for both nouveau and nvidia
  # -----------------------------------------------------------------
  hardware.opengl.enable = true;

  # -----------------------------------------------------------------
  # Pull the proprietary NVIDIA driver that matches the running kernel
  # -----------------------------------------------------------------
  # Use the latest driver package that ships with the current kernel.
  # If you prefer a specific version, replace `linuxPackages_latest` with
  # the appropriate set, e.g. `linuxPackages_6_6`.
  hardware.nvidia.package = pkgs.linuxPackages_latest.nvidiaDrivers;

  # Enable the kernel‑mode‑setting (KMS) component – recommended
  hardware.nvidia.modesetting.enable = true;

  # Tell the X server (and Wayland) to use the NVIDIA driver instead of nouveau
  services.xserver.videoDrivers = ["nvidia"];
  # Bind only GPU to VFIO
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=10de:2705,10de:22bb" # Only GPU IDs
  ];
}
