{...}: {
  # hardware.nvidia = {
  #   nvidiaSettings = true;
  #   open = true;
  # };

  # services.xserver.videoDrivers = ["nvidia"];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true; # Required for Steam
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false; # Use proprietary drivers for best performance
      nvidiaSettings = true; # Minimal install
      # package = config.boot.kernelPackages.nvidiaPackages.latest; # Latest driver
    };
  };

  # Enable NVIDIA driver
  services.xserver.videoDrivers = ["nvidia"];
}
