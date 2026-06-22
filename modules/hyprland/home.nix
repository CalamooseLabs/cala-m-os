{
  lib,
  pkgs,
  ...
}: {
  home.packages = [
    pkgs.wl-clipboard
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    package = null;
    portalPackage = null;

    xwayland.enable = true;

    configType = "hyprlang";

    extraConfig = ''
    '';

    settings = {
      "$mod" = "SUPER";

      general = {
        layout = lib.mkDefault "scrolling";

        # Custom feel: more breathing room + a thin accent-gradient border.
        gaps_in = 5;
        gaps_out = 12;
        border_size = 2;
        # cyan -> green accent gradient (matches the waybar accents). mkForce to
        # win over stylix's hyprland border theming.
        "col.active_border" = lib.mkForce "rgba(73cef4ee) rgba(c9d05cee) 45deg";
        "col.inactive_border" = lib.mkForce "rgba(2b2b2baa)";
      };

      input = {
        numlock_by_default = true;
      };

      # --- Custom window look ------------------------------------------------
      decoration = {
        rounding = 10;
        active_opacity = 0.96;
        inactive_opacity = 0.90;

        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = true;
          ignore_opacity = true;
          xray = false;
        };

        # shadow.color is themed by stylix (base00); we only size it here.
        shadow = {
          enabled = true;
          range = 18;
          render_power = 3;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "wind, 0.05, 0.9, 0.1, 1.05"
          "overshot, 0.13, 0.99, 0.29, 1.05"
          "smoothOut, 0.36, 0, 0.66, -0.56"
        ];
        animation = [
          "windows, 1, 5, wind, slide"
          "windowsIn, 1, 5, overshot, slide"
          "windowsOut, 1, 4, smoothOut, slide"
          "border, 1, 8, default"
          "fade, 1, 6, default"
          "workspaces, 1, 5, wind"
        ];
      };

      # Tasteful rules for the windows Hyprland spawns: common dialogs float,
      # picture-in-picture floats + stays pinned.
      windowrule = [
        "float, class:^(pavucontrol)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(org.gnome.Calculator)$"
        "float, title:^(Open File)(.*)$"
        "float, title:^(Save File)(.*)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
      ];

      misc = {
        disable_hyprland_logo = lib.mkForce true;
        disable_splash_rendering = lib.mkForce true;
      };

      ecosystem = {
        no_donation_nag = lib.mkForce true;
        no_update_news = lib.mkForce true;
      };

      scrolling = {
        fullscreen_on_one_column = true;
        focus_fit_method = 1;
      };

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod SHIFT, mouse:272, resizewindow"
      ];

      bind = [
        "$mod, grave, exec, $TERMINAL"
        "$mod, B, exec, $BROWSER"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, tab, cyclenext"
        "$mod, Q, killactive"
        "$mod SHIFT, F, fullscreen"
        "$mod, space, exec, pkill rofi || rofi-persona"

        "$mod, period, layoutmsg, swapcol r"
        "$mod, comma, layoutmsg, swapcol l"
        "$mod, slash, layoutmsg, promote"
        "$mod SHIFT, equal, layoutmsg, colresize +0.1"
        "$mod SHIFT, minus, layoutmsg, colresize -0.1"
      ];
    };
  };
}
