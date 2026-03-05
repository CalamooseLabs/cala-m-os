{
  pkgs,
  lib,
  ...
}: {
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "desc:Microstep MPG322UX OLED 0x01010101, 3840x2160@240, 0x0, 1, bitdepth, 10, cm, hdr, sdrbrightness, 1.2, sdrsaturation, 1.0"
        # "HDMI-A-1, 3840x2160@60, auto, 1, mirror, desc:Microstep MPG322UX OLED 0x01010101" # Mirror if any other output detected
        # "HDMI-A-2, 3840x2160@60, auto, 1, mirror, desc:Microstep MPG322UX OLED 0x01010101" # Mirror if any other output detected
        ", 3840x2160@60, auto, 1, mirror, desc:Microstep MPG322UX OLED 0x01010101" # Mirror if any other output detected
      ];

      binde = let
        pactl = lib.getExe' pkgs.pulseaudio "pactl";
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
      ];
    };
  };
}
