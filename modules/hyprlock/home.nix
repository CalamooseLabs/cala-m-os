{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  bgMode = osConfig.cala.lockscreen.background;
  frameDir = ../../assets/lock-frames;
  frameCount = 24;
  reloadEvery = 1;

  # Active-style palette + accent tokens (see hosts/_core/options.nix →
  # calamoose.style). Accents follow the chosen style; calamooselabs resolves to
  # the same 73cef4/c9d05c/f43753 it used before, thecompany to its brand blues,
  # blank to neutral grays. Neutral text greys below are left literal — they read
  # fine on any dark background and re-mapping them would shift the house look.
  c = osConfig.stylix.base16Scheme;
  accent = "rgb(${lib.removePrefix "#" c.base0C})"; # primary tick / outline
  okColor = "rgb(${lib.removePrefix "#" c.base0B})"; # check_color
  failColor = "rgb(${lib.removePrefix "#" c.base08})"; # fail_color
  fgColor = "rgb(${lib.removePrefix "#" c.base05})"; # input text

  # Per-style still background: the house lock art for calamooselabs, the style's
  # own wallpaper for the branded/blank looks. (The drift/"dynamic" frames are
  # hand-coloured house art and stay as-is when that mode is selected.)
  stillPath =
    if osConfig.calamoose.style == "thecompany"
    then "${../../assets/thecompany-wallpaper.png}"
    else if osConfig.calamoose.style == "blank"
    then "${../../assets/blank-wallpaper.png}"
    else "${../../assets/lockscreen-bg.png}";

  # "dynamic": rasterize the drift frames to PNGs once, at build time.
  framePngs = pkgs.runCommand "hyprlock-aurora-frames" {nativeBuildInputs = [pkgs.resvg];} ''
    mkdir -p "$out"
    for f in ${frameDir}/*.svg; do
      resvg --width 1280 --height 720 "$f" "$out/$(basename "$f" .svg).png"
    done
  '';

  # cycle the pre-rendered PNGs by wall-clock; hyprlock crossfades between them.
  dynamicReload = pkgs.writeShellScript "hyprlock-bg-dynamic" ''
    i=$(( ($(date +%s) / ${toString reloadEvery}) % ${toString frameCount} ))
    printf '%s' "${framePngs}/$(printf 'f%03d' "$i").png"
  '';

  baseBg = {
    monitor = "";
    blur_passes = 1;
    blur_size = 4;
    brightness = 0.85;
  };
  backgroundFor =
    if bgMode == "dynamic"
    then [
      (baseBg
        // {
          path = "${framePngs}/f000.png";
          reload_cmd = "${dynamicReload}";
          reload_time = reloadEvery;
        })
    ]
    else [(baseBg // {path = stillPath;})];
in {
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = lib.mkForce true;
        grace = lib.mkForce 0;
        hide_cursor = lib.mkForce true;
        no_fade_in = lib.mkForce false;
      };

      auth = {
        fingerprint = {
          enabled = true;
        };
      };

      # Background mode is chosen by cala.lockscreen.background (declared above).
      background = lib.mkForce backgroundFor;

      # Cyan accent ticks: a vertical bar beside the meta, a rule above the date.
      shape = [
        {
          monitor = "";
          size = "3, 80";
          color = accent;
          rounding = 0;
          border_size = 0;
          position = "50, -60";
          halign = "left";
          valign = "top";
        }
        {
          monitor = "";
          size = "74, 3";
          color = accent;
          rounding = 0;
          border_size = 0;
          position = "62, 420";
          halign = "left";
          valign = "bottom";
        }
      ];

      label = [
        # top-left meta
        {
          monitor = "";
          text = "  LOCKED";
          font_size = 16;
          font_family = "MesloLGS NF";
          color = accent;
          position = "66, -56";
          halign = "left";
          valign = "top";
        }
        {
          monitor = "";
          text = "cmd[update:0] echo \"$(whoami)@$(hostname)\"";
          font_size = 20;
          font_family = "MesloLGS NF";
          color = "rgb(cfd2d4)";
          position = "66, -96";
          halign = "left";
          valign = "top";
        }

        # date (raised to clear the clock)
        {
          monitor = "";
          text = "cmd[update:60000] date +'%A · %d %B %Y'";
          font_size = 24;
          font_family = "MesloLGS NF";
          color = "rgb(b9bcbe)";
          position = "62, 360";
          halign = "left";
          valign = "bottom";
        }

        # oversized clock, bottom-left. The meridiem is folded into this one
        # label (not a separate widget) so it can never overlap the time — a
        # separate AM/PM needs a pixel-perfect x, which hyprlock's font scaling
        # makes unreliable across resolutions.
        {
          monitor = "";
          text = "cmd[update:1000] date +'%I:%M %p'";
          font_size = 160;
          font_family = "MesloLGS NF";
          color = "rgb(f6f6f6)";
          position = "56, 70";
          halign = "left";
          valign = "bottom";
        }

        # password caption + hint, bottom-right
        {
          monitor = "";
          text = "PASSWORD";
          font_size = 15;
          font_family = "MesloLGS NF";
          color = "rgb(76797b)";
          position = "-80, 150";
          halign = "right";
          valign = "bottom";
        }
        {
          monitor = "";
          text = "Enter to unlock · fingerprint ready";
          font_size = 15;
          font_family = "MesloLGS NF";
          color = "rgb(76797b)";
          position = "-80, 50";
          halign = "right";
          valign = "bottom";
        }
      ];

      input-field = lib.mkForce [
        {
          monitor = "";
          size = "320, 50";
          position = "-80, 92";
          halign = "right";
          valign = "bottom";
          rounding = 4;
          outline_thickness = 2;
          dots_center = true;
          fade_on_empty = false;
          outer_color = accent;
          inner_color = "rgba(20, 22, 24, 0.55)";
          font_color = fgColor;
          check_color = okColor;
          fail_color = failColor;
          placeholder_text = "";
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [
        "hyprlock"
      ];

      bind = ["$mod, L, exec, hyprlock"];
    };
  };
}
