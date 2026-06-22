{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.yubikey-provision;
in {
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  options.programs.yubikey-provision = {
    enable = lib.mkEnableOption "the yubikey-provisoin command (provision a spare Yubikey)";
  };

  config = lib.mkIf cfg.enable {
    programs.antlers-scripts = {
      enable = true;
      yubikey-provision = {
        enable = true;
      };
    };
  };
}
