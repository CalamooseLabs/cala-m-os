{ inputs, pkgs, lib, ... }:

{
  # # Enable the X11 windowing system
  services.xserver.enable = true;

  # # Configure keymap in X11
  services.xserver.xkb.layout = "us";

 programs.hyprland = {
   enable = true;
   package = lib.mkForce inputs.hyprland.packages."${pkgs.system}".hyprland;
   portalPackage = lib.mkForce inputs.hyprland.packages."${pkgs.system}".xdg-desktop-portal-hyprland;
 };
}
