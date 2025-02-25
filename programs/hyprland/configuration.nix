{ inputs, pkgs, ... }:

{
  # Enable the X11 windowing system.
    services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };
}
