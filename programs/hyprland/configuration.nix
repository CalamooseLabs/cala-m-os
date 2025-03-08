{ pkgs, ... }:

{
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Extra Portal Configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal];
    configPackages = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal
    ];

    config.common.default = "*";
    config.hyprland.default = ["hyprland"];
  };

  # Login Service
  services.greetd.settings.default_session.command = "${pkgs.hyprland}/bin/Hyprland &> /dev/null";

  programs.hyprland = {
    enable = true;
  };
}
