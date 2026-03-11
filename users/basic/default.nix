{isDefaultUser, ...}: {...}: let
  username =
    if isDefaultUser
    then "hub"
    else baseNameOf (toString ./.);

  modules = [
    "agenix"
    "ashell"
    "bash"
    "easyeffects"
    "fingerprint-scanner"
    "fonts"
    "ghostty"
    "git"
    "gpg"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "imv"
    "librewolf"
    "neovim"
    "nh"
    "nwg-dock"
    "proton-pass"
    "rebuild-config"
    "rofi"
    "stylix"
    "spotify"
    "steam"
    "vlc"
    "yubikey"
    "zathura"
  ];
in {
  imports = [
    (import ../_core {
      username = username;
      import_modules = modules;
    })
  ];
}
