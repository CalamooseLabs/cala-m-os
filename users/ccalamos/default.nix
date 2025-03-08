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
      "hyprland"
      "hyprlock"
      "hyprpaper"
      "imv"
      "lazygit"
      "neovim"
      "plex-desktop"
      "qutebrowser"
      "rofi"
      "stylix"
      "vivaldi"
      "waybar"
      "yazi"
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
