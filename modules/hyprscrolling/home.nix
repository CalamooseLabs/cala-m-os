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

      bind = [
        "$mod, period, layoutmsg, movewindowto r"
        "$mod, comma, layoutmsg, movewindowto l"
      ];

      plugin = {
        hyprscrolling = {
          fullscreen_on_one_column = true;
        };
      };
    };
  };
}
