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
}
