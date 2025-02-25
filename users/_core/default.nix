{ username, import_programs, user_home ? null, ... }:

let
  user_home_path = if user_home == null then "/home/${username}" else user_home;

  root_path = "${builtins.dirname ./.}/../..";
  user_config_path = "${root_path}/users/${username}/home.nix";
  programs_path = "${root_path}/programs";

  user_configuration = "${user_config_path}/configuation.nix";
  user_home_configuration = "${user_config_path}/home.nix";

  # Add tracing to log program imports
  makeProgramConfigs = name: filename: builtins.trace
    "Importing ${name}/${filename}"
    (import (programs_path + "/${name}/${filename}") {
      inherit username user_home_path;
    });

  # Add tracing to log the list of programs being imported
  config_imports = builtins.trace "Config imports: ${import_programs}"
    (map (name: makeProgramConfigs name "configuration.nix") import_programs);

  home_imports = builtins.trace "Home imports: ${import_programs}"
    (map (name: makeProgramConfigs name "home.nix") import_programs);
in
{
  imports = [
    (builtins.trace "Importing core configuration" ./configuration.nix { inherit username; }) # Core Config
    (builtins.trace "Importing user configuration" user_configuration) # User Config
  ] ++ config_imports;

  home-manager = {
    users = {
      "${username}" = {
        imports = [
          (builtins.trace "Importing core home configuration" ./home.nix { inherit username user_home_path; }) # Core Home Config
          (builtins.trace "Importing user home configuration" user_home_configuration) # User Home Config
        ] ++ home_imports;
      };
    };
  };
}
