{...}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  services.xserver.videoDrivers = ["modesetting"];

  hardware.enableRedistributableFirmware = true;
  boot.initrd.kernelModules = ["amdgpu"];
}
