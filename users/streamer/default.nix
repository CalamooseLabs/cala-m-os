{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "bash"
    "bitfocus-companion"
    "fonts"
    "niri"
    "obs-studio"
    "openssh"
    "teleprompter"
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
