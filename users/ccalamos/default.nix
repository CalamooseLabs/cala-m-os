{...}: let
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
    "hypridle"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "imv"
    "ios"
    "lazygit"
    "neovim"
    "plex-desktop"
    "qutebrowser"
    "rofi"
    "scanner"
    "share-internet"
    "stylix"
    "vivaldi"
    "vlc"
    "vpn"
    "waybar"
    "wifi"
    "yazi"
    "yubikey"
    "zathura"
    "zed-editor"
  ];
in {
  imports = [
    (import ../_core {
      username = username;
      import_programs = import_programs;
    })
  ];
}
