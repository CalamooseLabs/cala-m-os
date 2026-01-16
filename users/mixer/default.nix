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
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "hyprscrolling"
    "imagemagick"
    "imv"
    "neovim"
    "obs-studio"
    "rawtherapee"
    "rofi"
    "stylix"
    "spotify"
    "streamdeck"
    "vivaldi"
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
