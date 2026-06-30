{...}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  services.xserver.videoDrivers = ["amdgpu"];

  hardware.enableRedistributableFirmware = true;
  boot.initrd.kernelModules = ["amdgpu"];

  # Stable symlinks to the AMD card/render nodes (renderD*/card* numbering is not
  # stable across boots / multi-GPU). Lets a Wayland compositor be pinned to the
  # AMD GPU — e.g. broadcast sets AQ_DRM_DEVICES=/dev/dri/amd-card:... so the AMD
  # card is Aquamarine's primary renderer and emits the LINEAR-importable buffers
  # the DisplayLink/evdi teleprompter needs (the proven devbox AMD path), leaving
  # the NVIDIA card free for OBS NVENC. Matches nothing until an AMD GPU is
  # present, so it is safe to import anywhere.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x1002", SYMLINK+="dri/amd-render"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x1002", SYMLINK+="dri/amd-card"
  '';
}
