{config, ...}: {
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta; # 570.xx (5090 support)
  };

  services.xserver.videoDrivers = ["nvidia" "modesetting"];
}
