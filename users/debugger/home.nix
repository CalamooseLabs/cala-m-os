{...}: {pkgs, ...}: {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  services.easyeffects = {
    preset = "FW16";
  };
}
