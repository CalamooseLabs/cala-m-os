{isDefaultUser, ...}: {cala-m-os, ...}: let
  username =
    if isDefaultUser
    then cala-m-os.globals.defaultUser
    else baseNameOf (toString ./.);

  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "bash"
    "bat"
    "btop"
    "davinci-resolve"
    "easyeffects"
    "fonts"
    "ghostty"
    "git"
    "geforce-now"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "hytale"
    "imagemagick"
    "imv"
    "minecraft"
    "neovim"
    "nh"
    "obs-studio"
    "rawtherapee"
    "rebuild-config"
    "rofi"
    "stylix"
    "spotify"
    "steam"
    "streamdeck"
    "teleprompter"
    "vlc"
    "waybar"
    "yubikey"
  ];
in {
  imports = [
    (import ../_core {
      username = username;
      import_modules = modules;
      uuid = uuid;
    })
  ];
}
