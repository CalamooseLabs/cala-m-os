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

    extraConfig = ''
    '';

    settings = {
      "$mod" = "SUPER";

      general = {
        layout = lib.mkDefault "scrolling";
      };

      input = {
        numlock_by_default = true;
      };

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
        "$mod, space, exec, pkill rofi || rofi -show drun -showicons"

        "$mod, period, layoutmsg, swapcol r"
        "$mod, comma, layoutmsg, swapcol l"
        "$mod, slash, layoutmsg, promote"
        "$mod SHIFT, equal, layoutmsg, colresize +0.1"
        "$mod SHIFT, minus, layoutmsg, colresize -0.1"
      ];
    };
  };
}
