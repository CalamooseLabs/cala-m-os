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

    xwayland.enable = true;

    extraConfig = ''
    '';

    settings = {
      "$mod" = "SUPER";

      input = {
        numlock_by_default = true;
      };

      misc = {
        disable_hyprland_logo = lib.mkForce true;
        disable_splash_rendering = lib.mkForce true;
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
        "$mod, space, exec, pkill rofi || rofi -show drun -showicons"
      ];
    };
  };
}
