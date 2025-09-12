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

      hyprscolling = {
        fullscreen_on_one_column = true;
      };
    };
  };
}
