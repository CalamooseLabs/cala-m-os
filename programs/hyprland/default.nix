{ lib, pkgs, inputs, ... }:

{
  # programs.hyprland = {
  #     enable = true;
  #     package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  #     portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  # };

  wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;

      systemd = {
        enable = true;
        variables = [ "--all" ]; # fix for https://wiki.hyprland.org/Nix/Hyprland-on-Home-Manager/#programs-dont-work-in-systemd-services-but-do-on-the-terminal
        # TODO(hyprland): experiment with whether this is required.
        # Same as default, but stop the graphical session too
        extraCommands = lib.mkBefore [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };

      extraConfig = ''
      '';

      settings = {
        "$mod" = "SUPER";

        exec-once = [
          ''${inputs.hyprpaper.packages."${pkgs.system}".default}/bin/hyprpaper''
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

        # Repeated Binds
        binde =
          let
            pactl = lib.getExe' pkgs.pulseaudio "pactl";
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
            ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
            ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ];

        bind = [
          "$mod, Q, exec, ghostty"
          "$mod, P, exec, proton-pass"
          "$mod, B, exec, vivaldi"
          "$mod, L, exec, hyprlock"

          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"
          "$mod, tab, cyclenext"
          "$mod, escape, killactive"
          "$mod, space, exec, rofi -show drun -showicons"
        ];
      };
    };
}
