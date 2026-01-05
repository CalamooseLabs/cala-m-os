{
  lib,
  pkgs,
  ...
}: let
  internalAMDDisplay = "eDP-1, 2560x1600@165, 0x0, 1";
  internalNvidiaDisplay = "eDP-2, 2560x1600@165, 0x0, 1";
in {
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "${internalAMDDisplay}" # Laptop Screen
        "${internalNvidiaDisplay}"
        "DP-9, 2560x1440@165, -640x-1600, 1" # Office Monitor
      ];

      # Repeated Binds
      binde = let
        pactl = lib.getExe' pkgs.pulseaudio "pactl";
        brightnessctl = lib.getExe' pkgs.brightnessctl "brightnessctl";
      in [
        # Volume - Output
        ", XF86AudioRaiseVolume, exec, ${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, ${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
        # Volume - Input
        ", XF86AudioRaiseVolume, exec, ${pactl} set-source-volume @DEFAULT_SOURCE@ +5%"
        ", XF86AudioLowerVolume, exec, ${pactl} set-source-volume @DEFAULT_SOURCE@ -5%"
        # Volume - Mute
        ", XF86AudioMute, exec, ${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86AudioMute, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"

        # Brightness
        ", XF86MonBrightnessUp, exec, ${brightnessctl} set +5%"
        ", XF86MonBrightnessDown, exec, ${brightnessctl} set 5%-"
      ];

      bindl = [
        ", switch:on:Lid Switch, exec, hyprlock"
        ", switch:on:Lid Switch, exec, hyprctl keyword monitor 'eDP-2, disable'"
        ", switch:off:Lid Switch, exec, hyprctl keyword monitor '${internalNvidiaDisplay}'"
      ];
    };
  };
}
