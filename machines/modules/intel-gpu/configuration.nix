{pkgs, ...}: {
  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      intel-gpu-tools
    ];
  };

  hardware.intel-gpu-tools.enable = true;
}
