{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "bash"
    "bat"
    "btop"
    "chromium"
    "geforce-now"
    "ghostty"
    "git"
    "hyprland"
    "hytale"
    "minecraft"
    "moosefetch"
    "neovim"
    "nh"
    "openssh"
    "rofi"
    "steam"
    "stylix"
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
