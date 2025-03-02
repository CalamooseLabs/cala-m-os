{ lib, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
      enable = true;

      xwayland.enable = true;

      # systemd = {
      #   enable = true;
      #   variables = [ "--all" ]; # fix for https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#programs-dont-work-in-systemd-services-but-do-on-the-terminal
      #   # TODO(hyprland): experiment with whether this is required.
      #   # Same as default, but stop the graphical session too
      #   extraCommands = lib.mkBefore [
      #     "systemctl --user stop graphical-session.target"
      #     "systemctl --user start hyprland-session.target"
      #   ];
      # };

      extraConfig = ''
      '';

      settings = {
        "$mod" = "SUPER";

        debug = {
          disable_logs = lib.mkForce true;
          enable_stdout_logs = lib.mkForce false;
          suppress_errors = lib.mkForce true;
        };

        exec-once = [
          "hyprlock"
        ];

        input = {
          numlock_by_default = true;
        };

        monitor = [
          "eDP-1, 2256x1504@60, 0x0, 1"
          "DP-5, 2560x1440@60, 2560x-1504, 1"
          "DP-6, 2560x1440@60, 0x-1504, 1"
          "DP-7, 2560x1440@60, 2560x-1504, 1"
          "DP-8, 2560x1440@60, 0x-1504, 1"
        ];

        misc = {
          disable_hyprland_logo = lib.mkForce true;
          disable_splash_rendering = lib.mkForce true;
        };

        # Repeated Binds
        binde =
          let
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
