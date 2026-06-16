{pkgs, ...}: {
  hardware.graphics = {
    # Populate /run/opengl-driver/lib so Plex (and others) can hardware-transcode
    # on the passed-through GPU.
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      intel-gpu-tools
    ];
  };

  hardware.intel-gpu-tools.enable = true;
}
