{...}: {
  hardware.nvidia = {
    nvidiaSettings = true;
    open = true;
  };

  services.xserver.videoDrivers = ["nvidia"];
}
