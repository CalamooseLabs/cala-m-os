{
  inputs,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland = {
    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprscrolling
    ];

    settings = {
      general = {
        layout = "scrolling";
      };

      hyprscrolling = {
        fullscreen_on_one_column = true;
      };
    };
  };
}
