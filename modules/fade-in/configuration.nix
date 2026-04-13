{pkgs, ...}: let
  fadein = pkgs.callPackage ./fadein.nix {};
in {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [fadein];

  # Screenwriting fonts
  fonts.packages = with pkgs; [
    courier-prime
    liberation_ttf
    dejavu_fonts
  ];
}
