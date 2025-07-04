{
  pkgs,
  lib,
  config,
  ...
}: let
  rofi-calculator = pkgs.writeShellScriptBin "rcalculator" (builtins.readFile ./scripts/calculator.sh);
  rofi-powermenu = pkgs.writeTextFile {
    name = "rofi_powermenu";
    destination = "/bin/powermenu";
    executable = true;
    text = builtins.readFile ./scripts/powermenu.sh;
  };
in {
  home.packages = [
    pkgs.bc
    rofi-powermenu
    rofi-calculator
  ];
  programs.rofi = {
    enable = true;
    package =
      pkgs.rofi-wayland.overrideAttrs ({...}: {mesonFlags = ["-Dxcb=disabled"];});
    extraConfig = {
      modi = "drun,calc:rcalculator";
      icon-theme = "Papirus-Dark";
      show-icons = true;
      terminal = "ghostty";
      location = 0;
      disable-history = false;
      hide-scrollbar = true;
      sidebar-mode = true;
      display-drun = "Apps";
      drun-display-format = "{name}";
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in
      lib.mkForce {
        "*" = {
          bg-col = mkLiteral "${config.stylix.base16Scheme.base03}";
          bg-col-light = mkLiteral "${config.stylix.base16Scheme.base03}";
          border-col = mkLiteral "${config.stylix.base16Scheme.base02}";
          selected-col = mkLiteral "${config.stylix.base16Scheme.base03}";
          pink = mkLiteral "${config.stylix.base16Scheme.base0B}";
          fg-col = mkLiteral "${config.stylix.base16Scheme.base06}";
          fg-col2 = mkLiteral "${config.stylix.base16Scheme.base0B}";
          grey = mkLiteral "${config.stylix.base16Scheme.base02}";

          width = mkLiteral "450px";
        };

        "element-text, element-icon , mode-switcher" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };

        "window" = {
          height = mkLiteral "500px";
          border = mkLiteral "3px";
          border-radius = mkLiteral "15px";
          border-color = mkLiteral "@border-col";
          background-color = mkLiteral "@bg-col";
        };

        "mainbox" = {background-color = mkLiteral "@bg-col";};

        inputbar = {
          children = mkLiteral "[prompt,entry]";
          background-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "15px";
          padding = mkLiteral "2px";
        };

        prompt = {
          background-color = mkLiteral "@pink";
          padding = mkLiteral "6px";
          text-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "15px";
          margin = mkLiteral "20px 0px 0px 20px";
        };

        textbox-prompt-colon = {
          expand = false;
          str = ":";
        };

        entry = {
          padding = mkLiteral "6px";
          margin = mkLiteral "20px 0px 0px 10px";
          text-color = mkLiteral "@fg-col";
          background-color = mkLiteral "@bg-col";
        };

        listview = {
          border = mkLiteral "0px 0px 0px";
          padding = mkLiteral "6px 0px 0px";
          margin = mkLiteral "10px 0px 0px 20px";
          columns = 1;
          lines = 10;
          background-color = mkLiteral "@bg-col";
        };

        element = {
          padding = mkLiteral "5px";
          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@fg-col";
        };

        element-icon = {size = mkLiteral "25px";};

        "element selected" = {
          background-color = mkLiteral "@selected-col";
          text-color = mkLiteral "@fg-col2";
        };

        mode-switcher = {spacing = 0;};

        button = {
          padding = mkLiteral "10px";
          background-color = mkLiteral "@bg-col-light";
          text-color = mkLiteral "@grey";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };

        "button selected" = {
          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@pink";
        };
      };
  };
}
