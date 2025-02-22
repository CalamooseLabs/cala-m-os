{ config, lib, pkgs, inputs, ... }:

let
  programs_path = ../../programs;

  # Function to create imports
  makeProgramImport = name: import "${toString (programs_path + "/${name}/default.nix")}";

  # List of Programs
  import_programs = [
    "bat"
    "btop"
    "direnv"
    "ghostty"
    "git"
    "hyprpaper"
    "hyprland"
    "hyprlock"
    "neovim"
    "rofi"
    "vivaldi"
    "waybar"
    "zathura"
    "zed-editor"
  ];

  user_imports = map makeProgramImport import_programs;
in
{
  home.username = "ccalamos";
  home.homeDirectory = "/home/ccalamos";

  imports = user_imports;

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

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    noto-fonts
    meslo-lgs-nf

    # All Nerd Fonts
    nerd-fonts.fantasque-sans-mono
    nerd-fonts.zed-mono
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
}
