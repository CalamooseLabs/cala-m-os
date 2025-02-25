{ ... }:

let
  username = "ccalamos";
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
      "plex-desktop"
      "rofi"
      "vivaldi"
      "waybar"
      "zathura"
      "zed-editor"
    ];
in
{
  imports = [
    ../_core { inherit username import_programs; }
  ];
}
