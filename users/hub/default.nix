{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  # Minimal session host — just enough to run the compositor and switch personas
  modules = [
    "agenix"
    "bash"
    "direnv"
    "edit-config"
    "fingerprint-scanner"
    "fonts"
    "ghostty"
    "git"
    "gpg"
    "hypridle"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "neovim"
    "nh"
    "rebuild-config"
    "rofi"
    "waybar"
    "wifi"
    "yazi"
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
