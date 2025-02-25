{ pkgs, inputs, ... }:

let
  wallpaper = ./wallpapers/wallpaper.png;
in
{
    services.hyprpaper = {
        enable = true;
        package = inputs.hyprpaper.packages."${pkgs.system}".default;
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
