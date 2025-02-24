{ ... }:

let
  import_programs = [
    "bash"
    "bat"
    "btop"
    "direnv"
    "fonts"
    "ghostty"
    "git"
    "gpg"
    "hyprpaper"
    "hyprland"
    "hyprlock"
    "lazygit"
    "lf"
    "neovim"
    "rofi"
    "vivaldi"
    "waybar"
    "zathura"
    "zed-editor"
  ];

  programs_path = ../../programs;

  # Function to create imports
  makeProgramImport = name: import "${toString (programs_path + "/${name}/default.nix")}";

  user_imports = map makeProgramImport import_programs;
in
{
  home.username = "ccalamos";
  home.homeDirectory = "/home/ccalamos";

  imports = [ ../_core/home/.nix ] ++ user_imports;

  catppuccin.enable = true;
}
