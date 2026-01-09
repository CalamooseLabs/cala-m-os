{isDefaultUser, ...}: {...}: let
  username =
    if isDefaultUser
    then "hub"
    else baseNameOf (toString ./.);

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
