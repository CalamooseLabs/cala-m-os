{
  pkgs,
  lib,
  ...
}: let
  rofi-powermenu = pkgs.writeTextFile {
    name = "rofi_powermenu";
    destination = "/bin/powermenu";
    executable = true;
    text = builtins.readFile ./scripts/powermenu.sh;
  };
in {
  home.packages = [rofi-powermenu];
  programs.rofi = {
    enable = true;
    package =
      pkgs.rofi-wayland.overrideAttrs
      (oldAttrs: {mesonFlags = ["-Dxcb=disabled"];});
    extraConfig = {
      modi = "drun";
      icon-theme = "Papirus-Dark";
      show-icons = true;
      terminal = "ghostty";
      location = 0;
      disable-history = false;
      hide-scrollbar = true;
      sidebar-mode = true;
      # font = "FantasqueSansMono Nerd Font 14";
      display-drun = "Apps";
      drun-display-format = "{name}";
    };
    theme = lib.mkForce "material";
  };
}
