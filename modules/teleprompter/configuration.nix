{config, ...}: {
  boot = {
    extraModulePackages = [config.boot.kernelPackages.evdi];
    initrd = {
      kernelModules = [
        "evdi"
      ];
    };
  };

  services.xserver.videoDrivers = ["displaylink" "modesetting"];

  systemd.services.dlm.wantedBy = ["multi-user.target"];
}
