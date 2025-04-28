{isDefaultUser, ...}: {...}: let
  username =
    if isDefaultUser
    then "hub"
    else builtins.baseNameOf (toString ./.);

  modules = [
    "agenix"
    "bash"
    "bat"
    "bridge-internet"
    "btop"
    "direnv"
    "easyeffects"
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
    "ssh"
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
      import_modules = modules;
    })
  ];
}
