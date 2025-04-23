{pkgs, ...}: {
  hardware.sane = {
    enable = true;
    extraBackends = [pkgs.utsushi];
  };

  services = {
    ipp-usb.enable = true;
    udev.packages = [pkgs.utsushi];
  };
}
