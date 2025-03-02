{ inputs, pkgs, config, lib, ... }:

with lib;

let
  # Check if this module has already been loaded
  alreadyLoaded = config.programs.hyprland._loaded or false;
in {
  # Define an internal option to track if this module has been loaded
  options.programs.hyprland = {
    _loaded = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = "Whether the hyprland configuration has already been loaded";
    };
  };

  # Only apply configuration if not already loaded
  config = mkIf (!alreadyLoaded) {
    # Mark as loaded
    programs.hyprland._loaded = true;

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Configure keymap in X11
    services.xserver.xkb.layout = "us";

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    };
  };
}
