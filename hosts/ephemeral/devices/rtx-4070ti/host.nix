{...}: {
  boot.kernelParams = [
    # AMD IOMMU settings
    "amd_iommu=on"
    "iommu=pt" # Passthrough mode

    # VFIO binding
    "vfio-pci.ids=10de:2705,10de:22bb"

    # If IOMMU groups are problematic, add:
    "pcie_acs_override=downstream,multifunction"

    # Disable framebuffer
    "video=vesafb:off,efifb:off"
  ];

  # Ensure IOMMU support in kernel
  boot.kernelModules = [
    "vfio"
    "vfio_iommu_type1"
    "vfio_pci"
  ];

  # boot.blacklistedKernelModules = [
  #   "nvidia"
  #   "nvidia_modeset"
  #   "nvidia_uvm"
  #   "nvidia_drm"
  #   "nouveau"
  # ];

  # # Disable NVIDIA services
  # hardware.nvidia.modesetting.enable = false;
  # services.xserver.videoDrivers = lib.mkForce ["modesetting"];

  # boot.initrd.kernelModules = [
  #   "vfio_pci"
  #   "vfio"
  #   "vfio_iommu_type1"
  #   # "vfio_virqfd"
  # ];

  # boot.kernelParams = [
  #   "amd_iommu=on" # For your AMD system
  #   "iommu=pt"
  #   "vfio-pci.ids=10de:2705,10de:22bb" # Replace with your NVIDIA GPU IDs
  #   "video=efifb:off" # Disable framebuffer
  # ];

  # # Force early binding
  # boot.extraModprobeConfig = ''
  #   options vfio-pci ids=10de:2705,10de:22bb
  #   softdep nvidia pre: vfio-pci
  #   softdep nouveau pre: vfio-pci
  # '';

  # boot.kernelModules = [
  #   # Load VFIO first
  #   "vfio"
  #   "vfio_iommu_type1"
  #   "vfio_pci"
  #   # Do NOT load nvidia modules here
  # ];

  # # Ensure NVIDIA modules are not loaded
  # boot.extraModulePackages = lib.mkForce [];

  # # Ensure D-Bus can restart properly
  # systemd.services.dbus = {
  #   restartIfChanged = false;
  #   reloadIfChanged = true;
  # };

  # # Add timeout for activation
  # systemd.services.nixos-activation = {
  #   serviceConfig = {
  #     TimeoutSec = "300";
  #     Restart = "on-failure";
  #   };
  # };
}
