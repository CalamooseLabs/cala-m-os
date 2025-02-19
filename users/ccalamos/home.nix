{ config, lib, pkgs, inputs, ... }:

{
  home.username = "ccalamos";
  home.homeDirectory = "/home/ccalamos";

  home.stateVersion = "24.11"; # Please read the comment before changing.

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "vivaldi-stable.desktop";
      "x-scheme-handler/http" = "vivaldi-stable.desktop";
      "x-scheme-handler/https" = "vivaldi-stable.desktop";
      "x-scheme-handler/about" = "vivaldi-stable.desktop";
      "x-scheme-handler/unknown" = "vivaldi-stable.desktop";
    };
  };

  home.packages = [
  ];

  # plain files is through 'home.file'.
  home.file = {
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  catppuccin.enable = true;

  programs.zed-editor = {
    enable = true;
  };
  programs.neovim = {
    enable = true;
    extraConfig = ''
      set number relativenumber
      set tabstop=2
      set shiftwidth=2
      set expandtab
    '';
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  programs.ghostty.enable = true;
  programs.chromium.enable = true;
  programs.vivaldi.enable = true;
  programs.zathura.enable = true;
  programs.btop.enable = true;
  programs.bat.enable = true;
  programs.rofi.enable = true;
  programs.waybar.enable = true;
  programs.git = {
    enable = true;
    userName = "Cole J. Calamos";
    userEmail = "cole@calamos.family";
    signing = {
      key = "63C1F6DB3F13A405";
      signByDefault = true;
    };
    extraConfig = {
      safe.directory = [
        "/etc/nixos"
      ];
    };
  };

  programs.hyprlock = {
    enable = true;

    package = inputs.hyprlock.packages."${pkgs.system}".default;

    settings = {
      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = ''
            <span foreground="##cad3f5">Password...</span>
          '';
          shadow_passes = 2;
        }
      ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;

    extraConfig = ''
    '';

    settings = {
      "$mod" = "SUPER";

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
