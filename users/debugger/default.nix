{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "agenix-boot"
    "antlers"
    "appimage"
    "bash"
    "bat"
    "btop"
    "direnv"
    "easyeffects"
    "edit-config"
    "fade-in"
    "fingerprint-scanner"
    "flameshot"
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
    "openswitcher"
    "orion"
    "pdf-editor"
    "proton-pass"
    "rawtherapee"
    "rebuild-config"
    "remote-desktop"
    "remote-kvm"
    "restore-config"
    "rofi"
    "scanner"
    "solaar"
    "ssh"
    "steam"
    "stylix"
    "teleprompter"
    "termusic"
    "vibe"
    "vibe-server"
    "virt-manager"
    "vivaldi"
    "vlc"
    "vpn"
    "waybar"
    "wifi"
    "yazi"
    "yubikey"
    "yubikey-clone"
    "zathura"
    "zed-editor"
  ];
in {
  inherit modules;
  module = {cala-m-os, ...}: let
    username =
      if isDefaultUser
      then cala-m-os.globals.defaultUser
      else uuid;
  in {
    imports = [
      ./secrets
      (import ../_core {
        username = username;
        import_modules = modules;
        uuid = uuid;
      })
    ];
  };
}
