{isDefaultUser, ...}: {cala-m-os, ...}: let
  username =
    if isDefaultUser
    then cala-m-os.globalDefaultUser
    else builtins.baseNameOf (toString ./.);

  uuid = builtins.baseNameOf (toString ./.);

  modules = [
    "bash"
    "bat"
    "btop"
    "fonts"
    "ghostty"
    "git"
    "hyprland"
    "steam"
    "vivaldi"
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
