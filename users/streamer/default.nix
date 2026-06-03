{isDefaultUser, ...}: {cala-m-os, ...}: let
  username =
    if isDefaultUser
    then cala-m-os.globals.defaultUser
    else baseNameOf (toString ./.);

  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "bash"
    "fonts"
    "obs-studio"
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
