{
  pkgs,
  lib,
  inputs,
  ...
}: let
  # geforce-now = import ./package.nix {
  #   inherit pkgs;
  #   inherit lib;
  # };
in {
  # environment.systemPackages = [
  #   geforce-now
  # ];
  # # enable appimage support
  # programs.appimage.enable = true;
  # programs.appimage.binfmt = true;
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  imports = [
    inputs.flatpaks.nixosModules.default
    ./module.nix
  ];

  services.geforce-now.enable = true;
}
