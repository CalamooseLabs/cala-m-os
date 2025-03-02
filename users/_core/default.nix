{ username, import_programs, user_home ? null, ... }: { config, ... }:

let
  user_home_path = if user_home == null then "/home/${username}" else user_home;

  root_path = ../../.;
  user_config_path = "${root_path}/users/${username}";
  programs_path = "${root_path}/programs";

  user_configuration = "${user_config_path}/configuration.nix";
  user_home_configuration = "${user_config_path}/home.nix";

  # For system configuration, check if program is enabled
  makeProgramConfigs = name:
    let
      # Check if this program is already enabled in the configuration
      isEnabled = config.programs.${name}.enable or false;
    in
      if isEnabled
      then {} # Return empty attrset if already enabled
      else import (programs_path + "/${name}/configuration.nix");

  # For home-manager, import all programs without checking
  makeHomeConfigs = name: import (programs_path + "/${name}/home.nix");

  config_imports = map makeProgramConfigs import_programs;
  home_imports = map makeHomeConfigs import_programs;
in
{
  imports = [
    (import ./configuration.nix { username = username; }) # Core Config
    (import user_configuration { username = username; }) # User Config
  ] ++ config_imports;

  home-manager.users = {
    "${username}" = {
      imports = [
        (import ./home.nix { username = username; user_home_path = user_home_path; }) # Core Home Config
        (import user_home_configuration { username = username; }) # User Home Config
      ] ++ home_imports;
    };
  };
}
