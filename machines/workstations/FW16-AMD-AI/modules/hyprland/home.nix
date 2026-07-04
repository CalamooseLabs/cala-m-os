{
  lib,
  pkgs,
  ...
}: let
  # Lid handling that finds the internal panel by name instead of hardcoding
  # eDP-2 — the kernel enumerates it as eDP-1 with the AMD iGPU and eDP-2 with
  # the dGPU module, so a fixed name silently no-ops on the other config and
  # leaves windows stranded after undocking. `monitors all` is used so the panel
  # is still resolvable while it is disabled (lid shut).
  laptop-panel = pkgs.writeShellApplication {
    name = "laptop-panel";
    runtimeInputs = [pkgs.jq];
    text = ''
      name="$(hyprctl monitors all -j | jq -r '[.[] | select(.name | test("eDP"))][0].name')"
      [ -n "$name" ] && [ "$name" != "null" ] || exit 0
      case "''${1:-}" in
        off) hyprctl keyword monitor "$name, disable" ;;
        on) hyprctl keyword monitor "$name, 2560x1600@165, 0x0, 1" ;;
      esac
    '';
  };
in {
  home.packages = [laptop-panel];
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        # Internal panel matched by EDID description, not connector name: the
        # kernel enumerates it as eDP-1 (AMD iGPU) or eDP-2 (dGPU module), but
        # the physical BOE panel reports the same desc either way, so one rule
        # covers both. 2560x1600@165 native.
        "desc:BOE NE160QDM-NZ6, 2560x1600@165, 0x0, 1"
        # "desc:Microstep MPG322UX OLED 0x01010101, 3840x2160@240, -3840x0, 1, bitdepth, 10, cm, hdr, sdrbrightness, 1.2, sdrsaturation, 1.0"
        "desc:Microstep MPG322UX OLED 0x01010101, 3840x2160@240, -3840x0, 1"
        ", preferred, auto, 1"
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
        ", switch:on:Lid Switch, exec, ${lib.getExe laptop-panel} off"
        ", switch:off:Lid Switch, exec, ${lib.getExe laptop-panel} on"
      ];
    };
  };
}
