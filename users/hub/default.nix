{isDefaultUser, ...}: {cala-m-os, ...}: let
  username =
    if isDefaultUser
    then cala-m-os.globals.defaultUser
    else baseNameOf (toString ./.);

  uuid = baseNameOf (toString ./.);

  # Minimal session host — just enough to run the compositor and switch personas
  modules = [
    "agenix"
    "bash"
    "fonts"
    "ghostty"
    "hyprland"
    "hyprlock"
    "hyprpaper"
    "neovim"
    "rofi"
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
