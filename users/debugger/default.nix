{isDefaultUser, ...}: {cala-m-os, ...}: let
  username =
    if isDefaultUser
    then cala-m-os.globals.defaultUser
    else builtins.baseNameOf (toString ./.);

  uuid = builtins.baseNameOf (toString ./.);

  modules = [
    "agenix"
    "agenix-boot"
    "appimage"
    "bash"
    "bat"
    "btop"
    "direnv"
    "edit-config"
    "fingerprint-scanner"
    "fonts"
    "geforce-now"
    "ghostty"
    "git"
    "gpg"
    "hypridle"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "hyprscrolling"
    "imagemagick"
    "imv"
    "ios"
    "lanserver"
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
    "steam"
    "stylix"
    "tailscale"
    "virt-manager"
    "vivaldi"
    "vlc"
    "vpn"
    "waybar"
    "wifi"
    # "winboat"
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
