{isDefaultUser, ...}: {cala-m-os, ...}: let
  username =
    if isDefaultUser
    then cala-m-os.globals.defaultUser
    else baseNameOf (toString ./.);

  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "agenix-boot"
    "appimage"
    "bash"
    "bat"
    "btop"
    "direnv"
    "davinci-resolve"
    "easyeffects"
    "edit-config"
    "fade-in"
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
    "hytale"
    "imagemagick"
    "imv"
    "ios"
    "lazygit"
    "minecraft"
    "neovim"
    "nh"
    "obs-studio"
    "orion"
    "openswitcher"
    "pdf-editor"
    "proton-pass"
    "rawtherapee"
    "rebuild-config"
    "remote-desktop"
    "restore-config"
    "rofi"
    "scanner"
    "solaar"
    "spotify"
    "ssh"
    "steam"
    "stylix"
    # "tailscale"
    "teleprompter"
    "termusic"
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
