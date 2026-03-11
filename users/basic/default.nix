{isDefaultUser, ...}: {...}: let
  username =
    if isDefaultUser
    then "hub"
    else baseNameOf (toString ./.);

  modules = [
    "agenix"
    "ashell"
    "bash"
    "fonts"
    "ghostty"
    "git"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "imv"
    "librewolf"
    "neovim"
    "nh"
    "nwg-dock"
    "rebuild-config"
    "rofi"
    "stylix"
    "spotify"
    "steam"
    "vlc"
    "yubikey"
  ];
in {
  imports = [
    (import ../_core {
      username = username;
      import_modules = modules;
    })
  ];
}
