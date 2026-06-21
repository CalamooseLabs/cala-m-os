{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "bash"
    "bat"
    "btop"
    "fonts"
    "geforce-now"
    "ghostty"
    "git"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "hytale"
    "minecraft"
    "neovim"
    "nh"
    "obs-studio"
    "orion"
    "rebuild-config"
    "rofi"
    "steam"
    "stylix"
    "vlc"
    "waybar"
    "yubikey"
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
      (import ../_core {
        username = username;
        import_modules = modules;
        uuid = uuid;
      })
    ];
  };
}
