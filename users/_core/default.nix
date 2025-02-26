{ username, import_programs, user_home ? null, ... }: { ... }:

let
  user_home_path = if user_home == null then "/home/${username}" else user_home;

  root_path = ../../.;
  user_config_path = "${root_path}/users/${username}";
  programs_path = "${root_path}/programs";

  user_configuration = "${user_config_path}/configuration.nix";
  user_home_configuration = "${user_config_path}/home.nix";

  makeProgramConfigs = name: filename: import (programs_path + "/${name}/${filename}");

  config_imports = map (name: makeProgramConfigs name "configuration.nix") import_programs;
  home_imports = map (name: makeProgramConfigs name "home.nix") import_programs;
in
{
  imports = [
    (import ./configuration.nix { username = username; }) # Core Config
    user_configuration # User Config
  ] ++ config_imports;

  home-manager.users = {
    "${username}" = {
      imports = [
        (import ./home.nix { username = username; user_home_path = user_home_path; }) # Core Home Config
        user_home_configuration # User Home Config
      ] ++ home_imports;
    };
  };
}
