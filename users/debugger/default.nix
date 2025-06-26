{isDefaultUser, ...}: {cala-m-os, ...}: let
  username =
    if isDefaultUser
    then cala-m-os.globalDefaultUser
    else builtins.baseNameOf (toString ./.);

  uuid = builtins.baseNameOf (toString ./.);

  modules = [
    "agenix"
    "bash"
    "bat"
    "btop"
    "direnv"
    "edit-config"
    "fingerprint-scanner"
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
    "nh"
    "obs-studio"
    "pdf-editor"
    "rawtherapee"
    "rebuild-config"
    "remote-desktop"
    "restore-config"
    "rofi"
    "scanner"
    "spotify"
    "ssh"
    "stylix"
    "virt-manager"
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
      uuid = uuid;
    })
  ];
}
