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
    "easyeffects"
    "ghostty"
    "hyprland"
    "hyprpaper"
    "neovim"
    "obs-studio"
    "openssh"
    "rofi"
    "steam"
    "stylix"
    "spotify"
    "streamdeck"
    "vivaldi"
    "vlc"
    "waybar"
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
