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
    "easyeffects"
    "git"
    "hyprland"
    "hyprpaper"
    "neovim"
    "nh"
    "obs-studio"
    "openssh"
    "rebuild-config"
    "restore-config"
    "rofi"
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
