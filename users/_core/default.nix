{
  username,
  import_modules,
  uuid,
  user_home ? null,
  ...
}: {...}: let
  user_home_path =
    if user_home == null
    then "/home/${username}"
    else user_home;

  root_path = ../../.;
  user_config_path = "${root_path}/users/${uuid}";
  modules_path = "${root_path}/modules";

  user_configuration = "${user_config_path}/configuration.nix";
  user_home_configuration = "${user_config_path}/home.nix";

  makeModuleConfigs = name: filename: import (modules_path + "/${name}/${filename}");

  config_imports = map (name: makeModuleConfigs name "configuration.nix") import_modules;
  home_imports = map (name: makeModuleConfigs name "home.nix") import_modules;
in {
  imports =
    [
      ./secrets
      (import ./configuration.nix {username = username;}) # Core Config
      (import user_configuration {username = username;}) # User Config
    ]
    ++ config_imports;

  home-manager.users = {
    "${username}" = {
      imports =
        [
          (import ./home.nix {
            username = username;
            user_home_path = user_home_path;
          }) # Core Home Config
          (import user_home_configuration {username = username;}) # User Home Config
        ]
        ++ home_imports;
    };
  };
}
