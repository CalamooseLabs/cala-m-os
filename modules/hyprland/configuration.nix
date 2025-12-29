{
  inputs,
  pkgs,
  ...
}: {
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Extra Portal Configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;

    config.common.default = "*";
    config.hyprland.default = ["hyprland"];
  };

  programs.hyprland = {
    enable = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # Login Service
  services.greetd.settings.default_session.command = "start-hyprland &> /dev/null";
}
