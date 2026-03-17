{isDefaultUser, ...}: {...}: let
  username =
    if isDefaultUser
    then "hub"
    else baseNameOf (toString ./.);
  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "ashell"
    "bash"
    "easyeffects"
    "fingerprint-scanner"
    "fonts"
    "ghostty"
    "git"
    "hypridle"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "imv"
    "librewolf"
    "nautilus"
    "neovim"
    "nh"
    "nwg-dock"
    "proton-pass"
    "rebuild-config"
    "rofi"
    "stylix"
    "spotify"
    "steam"
    "teleprompter"
    "vlc"
    "yubikey"
    "zathura"
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
