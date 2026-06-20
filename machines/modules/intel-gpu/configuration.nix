{pkgs, ...}: {
  hardware.graphics = {
    # Populate /run/opengl-driver/lib for VAAPI/QSV — used both for Plex
    # hardware transcode and (on broadcast) for niri to render the DisplayLink
    # teleprompter on the Arc A310.
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

  # Stable symlink to the Intel render node so a compositor can be pinned to the
  # Intel GPU via render-drm-device (renderD* numbering is not stable across
  # boots / multi-GPU). Matches nothing until an Intel GPU is present, so it is
  # safe to import anywhere.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", SYMLINK+="dri/intel-render"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", SUBSYSTEMS=="pci", ATTRS{vendor}=="0x8086", SYMLINK+="dri/intel-card"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="evdi", SYMLINK+="dri/displaylink-card"
  '';
}
