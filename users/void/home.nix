{...}: {
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.impermanence.homeManagerModules.impermanence
  ];

  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];
}
