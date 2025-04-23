{pkgs, ...}: {
  home.packages = [
    pkgs.qflipper
    pkgs.usbutils
  ];
}
