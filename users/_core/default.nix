{ username, import_programs, user_home ? null ... }:

let
  user_home_path = if user_home == null then "/home/${username}" else user_home;

  root_path = "${builtins.dirname ./.}/../..";
  user_config_path = "${rootpath}/users/${username}"/home.nix;
  programs_path = "${rootpath}/programs"/.;

  makeProgramConfigs = name: filename: import "${toString (programs_path + "/${name}/${filename}")}";

  config_imports = map (name: makeProgramConfigs name "configuration.nix") import_programs;
  home_imports = map (name: makeProgramConfigs name "home.nix") import_programs;
in
{
  imports = [
    ./configuration.nix { inherit username; } # Core Config
    user_config_path/configuration.nix # User Config
  ] ++ config_imports;

  # This is where we will take the inputs and will use the importer from ./programs
  home-manager = {
    users = {
      "${username}" = {
        imports = [
          ./home.nix { inherit username user_home_path ; } # Core Home Config
        ] ++ home_imports;
      };
    };
  };
}
