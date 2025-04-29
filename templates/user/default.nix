{isDefaultUser, ...}: {...}: let
  username =
    if isDefaultUser
    then "hub"
    else builtins.baseNameOf (toString ./.);

  modules = [
  ];
in {
  imports = [
    (import ../_core {
      username = username;
      import_modules = modules;
    })
  ];
}
