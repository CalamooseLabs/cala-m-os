{
  pkgs,
  config,
  ...
}: let
  # Selected style for this host (see hosts/_core/options.nix → calamoose.style).
  style = config.calamoose.style;

  # A proper Nerd Font monospace is kept across every style: the terminal,
  # waybar, and rofi rely on its powerline/icon glyphs, so it is never themed
  # away even when a brand specifies its own display faces.
  mono = {
    package = pkgs.meslo-lgs-nf;
    name = "MesloLGS NF";
  };

  # The Company, Inc. display faces. The Brand Guidelines specify Adobe's
  # Polymath / Xanti Typewriter / Espiritu; those are not packaged, so we use
  # the free Google alternatives the guidelines themselves nominate (Outfit for
  # Polymath, BioRhyme for Xanti Typewriter). Slimmed to just these families to
  # keep the closure small.
  companyFonts = pkgs.google-fonts.override {
    fonts = ["Outfit" "BioRhyme"];
  };

  # Theme table — each entry is a complete visual style. `calamoose.style`
  # selects one; every host defaults to "calamooselabs".
  themes = {
    # House style: gruvbox-ish dark palette + photographic wallpaper.
    calamooselabs = {
      polarity = "dark";
      image = ../../assets/wallpaper.png;
      plymouthLogo = ../../assets/cala-m-os_logo.png;
      logoAnimated = true; # house logo already spins at boot — preserve it
      sansSerif = mono;
      serif = mono;
      base16Scheme = {
        base00 = "#282828";
        base01 = "#383838";
        base02 = "#484848";
        base03 = "#4c4c4c";
        base04 = "#b8b8b8";
        base05 = "#eeeeee";
        base06 = "#e8e8e8";
        base07 = "#feffff";
        base08 = "#f43753";
        base09 = "#dc9656";
        base0A = "#ffc24b";
        base0B = "#c9d05c";
        base0C = "#73cef4";
        base0D = "#b3deef";
        base0E = "#d3b987";
        base0F = "#a16946";
      };
    };

    # Minimal grayscale dark: a monochrome ramp, no accent hue, solid
    # (wallpaper-less) charcoal background. A distraction-free "blank slate".
    blank = {
      polarity = "dark";
      image = ../../assets/blank-wallpaper.png;
      plymouthLogo = ../../assets/cala-m-os_logo.png;
      logoAnimated = true; # same house logo as calamooselabs
      sansSerif = mono;
      serif = mono;
      base16Scheme = {
        base00 = "#1c1c1c";
        base01 = "#262626";
        base02 = "#303030";
        base03 = "#5c5c5c";
        base04 = "#999999";
        base05 = "#e6e6e6";
        base06 = "#f0f0f0";
        base07 = "#ffffff";
        base08 = "#cfcfcf";
        base09 = "#b0b0b0";
        base0A = "#e0e0e0";
        base0B = "#c2c2c2";
        base0C = "#d6d6d6";
        base0D = "#a6a6a6";
        base0E = "#bdbdbd";
        base0F = "#8a8a8a";
      };
    };

    # The Company, Inc. — brand theme per its Brand Guidelines. A "Dark Mode"
    # palette: Incognito Black (#0d1a1c) base, Fluorescent White (#e8f5f2)
    # foreground, and the electric Blue Screen of Death (#1c8fff) /
    # Circle-Back Cyan (#47c2f0) / Highlighter Green (#c7e88f) accents kept as
    # the on-brand colors. The red/orange/yellow/brown slots (which the brand
    # palette does not define) are harmonised fills so syntax highlighting stays
    # legible. Wallpaper + boot logo are the "Evil Eye" logomark.
    thecompany = {
      polarity = "dark";
      image = ../../assets/thecompany-wallpaper.png;
      plymouthLogo = ../../assets/thecompany-logomark.png;
      logoAnimated = false; # the "Evil Eye" lens is not rotationally symmetric
      sansSerif = {
        package = companyFonts;
        name = "Outfit";
      };
      serif = {
        package = companyFonts;
        name = "BioRhyme";
      };
      base16Scheme = {
        base00 = "#0d1a1c"; # Incognito Black — background
        base01 = "#13252a";
        base02 = "#1d343b";
        base03 = "#4a6b73"; # muted teal — comments
        base04 = "#8fb3b8";
        base05 = "#e8f5f2"; # Fluorescent White — foreground
        base06 = "#f3faf8";
        base07 = "#ffffff";
        base08 = "#ff6b81"; # red (harmonised)
        base09 = "#ff9d5c"; # orange (harmonised)
        base0A = "#ecd06a"; # yellow (harmonised)
        base0B = "#c7e88f"; # Highlighter Green — green
        base0C = "#47c2f0"; # Circle-Back Cyan — cyan
        base0D = "#1c8fff"; # Blue Screen of Death — blue / primary
        base0E = "#7ea2ff"; # periwinkle (on-brand blue family) — magenta slot
        base0F = "#6f9c96"; # muted teal (harmonised) — brown slot
      };
    };
  };

  theme = themes.${style};
in {
  stylix = {
    enable = true;
    autoEnable = true;

    inherit (theme) base16Scheme polarity image;

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 16;
    };

    fonts = {
      monospace = mono;
      inherit (theme) sansSerif serif;
    };

    targets = {
      plymouth = {
        logo = theme.plymouthLogo;
        # Stylix pre-rotates the logo through a full spin (96 frames) unless this
        # is disabled — fine for a symmetric mark, but it clips non-symmetric ones.
        logoAnimated = theme.logoAnimated;
      };
    };

    opacity = {
      terminal = 0.9;
    };
  };
}
