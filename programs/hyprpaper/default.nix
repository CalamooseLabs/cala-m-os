{ pkgs, inputs, ... }:

{
    services.hyprpaper = {
        enable = true;
        settings = {
          preload = [
            "./wallpapers/wallpaper.png"
          ];
          wallpaper = [
            "./wallpapers/wallpaper.png"
          ];
        };
    };
}
