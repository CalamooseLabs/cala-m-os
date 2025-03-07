{ lib, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
      enable = true;

      xwayland.enable = true;

      extraConfig = ''
      '';

      settings = {
        "$mod" = "SUPER";

        exec-once = [
          "hyprlock"
        ];

        input = {
          numlock_by_default = true;
        };

        monitor = [
          "eDP-1, 2256x1504@60, 0x0, 1"
          "desc:Microstep MSI MP341CQ 0x00000077, 3840x1440@60, -3840x0, 1"
          # "DP-5, 2560x1440@60, 2560x-1504, 1"
          # "DP-6, 2560x1440@60, 0x-1504, 1"
        ];

        misc = {
          disable_hyprland_logo = lib.mkForce true;
          disable_splash_rendering = lib.mkForce true;
        };

        # Repeated Binds
        binde = let
          pactl = lib.getExe' pkgs.pulseaudio "pactl";
          brightnessctl = lib.getExe' pkgs.brightnessctl "brightnessctl";
        in
        [
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

        bindm = [
          "$mod, mouse:272, movewindow"
        ];

        bind = [
          "$mod, grave, exec, ghostty"
          "$mod, P, exec, proton-pass"
          "$mod, B, exec, vivaldi"
          "$mod, L, exec, hyprlock"

          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"
          "$mod, tab, cyclenext"
          "$mod, Q, killactive"
          "$mod, space, exec, rofi -show drun -showicons"
        ];
      };
    };
}
