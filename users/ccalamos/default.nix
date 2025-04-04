{...}: let
  username = "ccalamos";
  import_programs = [
    "bash"
    "bat"
    "bridge-internet"
    "btop"
    "direnv"
    "flipperzero"
    "fonts"
    "ghostty"
    "git"
    "gpg"
    "hypridle"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "imagemagick"
    "imv"
    "ios"
    "lazygit"
    "neovim"
    "plex-desktop"
    "proton-pass"
    "rofi"
    "scanner"
    "sops"
    "spotify"
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
