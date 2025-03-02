{ ... }:

let
  wallpaper = ./wallpapers/wallpaper.png;
in
{
    services.hyprpaper = {
        enable = true;

        settings = {
          preload = [
            (builtins.toString wallpaper)
          ];
          wallpaper = [
            ",${builtins.toString wallpaper}"
          ];
        };
    };
}
