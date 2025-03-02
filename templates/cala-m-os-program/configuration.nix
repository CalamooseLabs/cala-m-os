{ config, lib, ... }:

with lib;

let
  program_name = "program";
  # Check if this module has already been loaded
  alreadyLoaded = config.programs."${program_name}"._loaded or false;
in {
  # Define an internal option to track if this module has been loaded
  options.programs."${program_name}" = {
    _loaded = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = "Whether the program's configuration has already been loaded";
    };
  };

  # Only apply configuration if not already loaded
  config = mkIf (!alreadyLoaded) {
    programs."${program_name}" = {
      _loaded = true;
      enable = true;
    };
  };
}
