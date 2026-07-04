{
  lib,
  pkgs,
  ...
}: let
  # $mod SHIFT R rescue: yank every window + the cursor back onto the internal
  # laptop panel. For when an external monitor is unplugged (e.g. undocking with
  # the lid shut) and windows are left running on a display that no longer
  # exists. The panel is found by name (eDP*) so it works whether the kernel
  # enumerates it as eDP-1 (AMD iGPU) or eDP-2 (dGPU module); falls back to the
  # first monitor on a deskop with no eDP.
  rescue-to-panel = pkgs.writeShellApplication {
    name = "rescue-to-panel";
    runtimeInputs = [pkgs.jq];
    text = ''
      edp="$(hyprctl monitors -j | jq -r '[.[] | select(.name | test("eDP"))][0].name // .[0].name')"
      [ -n "$edp" ] || exit 0

      hyprctl dispatch focusmonitor "$edp"
      ws="$(hyprctl monitors -j | jq -r --arg m "$edp" '.[] | select(.name == $m) | .activeWorkspace.id')"

      # Re-home every real workspace (id > 0 skips special) so none stay bound
      # to a monitor that no longer exists.
      hyprctl workspaces -j | jq -r '.[] | select(.id > 0) | .id' | while read -r w; do
        hyprctl dispatch moveworkspacetomonitor "$w" "$edp" || true
      done

      # Pull every window onto the visible workspace so nothing stays hidden.
      hyprctl clients -j | jq -r '.[].address' | while read -r a; do
        hyprctl dispatch movetoworkspacesilent "$ws,address:$a" || true
      done

      # Warp focus + cursor to the panel center so input follows.
      hyprctl dispatch focusmonitor "$edp"
      if read -r cx cy < <(hyprctl monitors -j | jq -r --arg m "$edp" \
        '.[] | select(.name == $m) | "\(.x + (.width / .scale / 2 | floor)) \(.y + (.height / .scale / 2 | floor))"'); then
        hyprctl dispatch movecursor "$cx" "$cy"
      fi
    '';
  };
in {
  home.packages = [
    pkgs.wl-clipboard
    rescue-to-panel
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
        gaps_in = 2;
        gaps_out = 8;
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
        active_opacity = 1.0;
        inactive_opacity = 0.94;

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
          # windowsMove governs the reflow when the waybar strip is reclaimed on
          # collapse/expand — a touch slower so windows visibly glide up/down to
          # fill the space instead of snapping.
          "windowsMove, 1, 6, wind"
          "border, 1, 8, default"
          "fade, 1, 6, default"
          "workspaces, 1, 5, wind"
        ];
      };

      # Tasteful rules for the windows Hyprland spawns: common dialogs float,
      # picture-in-picture floats + stays pinned.
      #
      # Hyprland 0.55 retired the old `windowrule = <effect>, <matcher>` /
      # windowrulev2 syntax. Matchers are now `match:<prop> <regex>`, effects
      # take explicit values (`float on`), and several effects can share a line.
      windowrule = [
        "match:class ^(pavucontrol)$, float on"
        "match:class ^(nm-connection-editor)$, float on"
        "match:class ^(org.gnome.Calculator)$, float on"
        "match:title ^(Open File)(.*)$, float on"
        "match:title ^(Save File)(.*)$, float on"
        "match:title ^(Picture-in-Picture)$, float on, pin on"
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
        # toggle the collapsible waybar (pairs with cala.waybar.collapse)
        "$mod, W, exec, cala-waybar-collapse"
        # rescue: pull all windows + cursor back onto the internal laptop panel
        "$mod SHIFT, R, exec, ${lib.getExe rescue-to-panel}"

        "$mod, period, layoutmsg, swapcol r"
        "$mod, comma, layoutmsg, swapcol l"
        "$mod, slash, layoutmsg, promote"
        "$mod SHIFT, equal, layoutmsg, colresize +0.1"
        "$mod SHIFT, minus, layoutmsg, colresize -0.1"
      ];
    };
  };
}
