{...}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  services.xserver.videoDrivers = ["amdgpu"];

  hardware.enableRedistributableFirmware = true;

  # amdgpu is deliberately NOT forced into the initrd here. Early KMS (amdgpu in
  # boot.initrd.kernelModules) is cosmetic — it only paints splash/console before
  # switch-root — but it makes the whole boot hostage to the DRM driver + GPU
  # firmware working inside stage-1: broadcast (RX 9060 RDNA4 discrete, kernel
  # 7.1) failed stage-1 with amdgpu in its initrd. This is ASIC-specific, not a
  # kernel problem — devbox boots the same kernel fine WITH amdgpu in its initrd
  # (Framework iGPU, via nixos-hardware) — but early KMS buys nothing worth that
  # risk on new silicon. amdgpu still loads normally in stage-2 via
  # services.xserver.videoDrivers above, which is all Hyprland/evdi need (late
  # probe races, e.g. greetd vs /dev/dri/amd-card, are handled at the consumer —
  # see hosts/broadcast). A consumer that truly wants early KMS (e.g. a
  # passthrough guest) must opt in with its own boot.initrd.kernelModules.

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
