{...}: let
  username = "ccalamos";
  import_programs = [
    "agenix"
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
    "obs-studio"
    "plex-desktop"
    "proton-pass"
    "rofi"
    "scanner"
    "spotify"
    "streamdeck"
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
    ./secrets
    (import ../_core {
      username = username;
      import_programs = import_programs;
    })
  ];
}
