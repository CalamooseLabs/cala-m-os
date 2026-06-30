{pkgs, ...}: {
  hardware.graphics = {
    # Populate /run/opengl-driver/lib for VAAPI/QSV — Plex hardware transcode on
    # the Arc (homelab arc-b50 guest).
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      intel-gpu-tools
      vpl-gpu-rt # oneVPL runtime (QuickSync) for Arc
    ];
  };

  hardware.intel-gpu-tools.enable = true;

  # GuC/HuC firmware for Intel GPUs. Battlemage (Arc B50, xe driver) loads
  # xe/bmg_guc_70.bin + xe/bmg_huc.bin; older Arc/iGPU use the i915/ blobs.
  hardware.enableRedistributableFirmware = true;

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # Stable symlinks to the Intel render/card nodes so a compositor can be pinned
  # to the Intel GPU via render-drm-device (renderD*/card* numbering is not stable
  # across boots / multi-GPU). Matches nothing until an Intel GPU is present, so
  # it is safe to import anywhere. (The DisplayLink/evdi symlink now lives in the
  # teleprompter module, where it belongs — broadcast swapped the Arc for an AMD
  # render GPU and no longer imports this module.)
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", SYMLINK+="dri/intel-render"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", SYMLINK+="dri/intel-card"
  '';
}
