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

    # package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    package = null;
    portalPackage = null;

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
