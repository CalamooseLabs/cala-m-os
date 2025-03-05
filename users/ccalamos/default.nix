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
      "qutebrowser"
      "rofi"
      "stylix"
      "vivaldi"
      "waybar"
      "yubikey"
      "zathura"
      "zed-editor"
    ];
in
{
  imports = [
    (import ../_core { username = username; import_programs = import_programs; })
  ];
}
