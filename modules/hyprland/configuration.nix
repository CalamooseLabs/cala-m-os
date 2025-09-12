{...}: {
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Extra Portal Configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # extraPortals = [
    #   pkgs.xdg-desktop-portal-hyprland
    # ];
    # configPackages = [
    #   pkgs.xdg-desktop-portal-hyprland
    # ];

    config.common.default = "*";
    config.hyprland.default = ["hyprland"];
  };

  # Login Service
  # services.greetd.settings.default_session.command = "hyprland &> /dev/null";
  services.greetd.settings.default_session.command = "hyprland";
}
