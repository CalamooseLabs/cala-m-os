{...}: {
  ### ----- Kernel & IOMMU -----------------------------------------
  boot.kernelParams = [
    "amd_iommu=on" # Threadripper IOMMU
    "iommu=pt" # host devices = pass‑through
    # Bind GPUs **early**, while initrd is still running
    "vfio-pci.ids=10de:2784,10de:22e8,8086:56a0,8086:56c0"
    "vfio-pci.disable_idle_d3=1" # avoids Intel reset issues
  ];
  boot.initrd.kernelModules = ["vfio_pci"];

  ### ----- Stop the normal drivers from loading -------------------
  boot.blacklistedKernelModules = [
    "nvidia"
    "nouveau" # all NVIDIA flavours
    "i915"
    "xe" # old + new Intel drivers
    "snd_hda_intel" # HDMI/DP audio
    "nvidiafb" # legacy framebuffer
  ];

  ### ----- No local X/Wayland session -----------------------------
  services.xserver.enable = false; # host runs headless via SSH/BMC
}
