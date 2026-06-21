{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.ssh-key-import;
in {
  # The ssh-key-import command now ships from the antlers scripts collection.
  # This module keeps the `programs.ssh-key-import` facade (enable + keyName) the
  # user profiles set, and delegates the install to programs.antlers-scripts.
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  options.programs.ssh-key-import = {
    enable = lib.mkEnableOption "the ssh-key-import command (download the Yubikey resident SSH keys on demand)";

    keyName = lib.mkOption {
      type = lib.types.str;
      default = "id_ed25519_sk";
      description = ''
        Filename (under ~/.ssh) the downloaded resident key is renamed to, with
        its public half written to <keyName>.pub. Matches the names the README
        and the user's authorized_keys expect.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.antlers-scripts = {
      enable = true;
      ssh-key-import = {
        enable = true;
        keyName = cfg.keyName;
      };
    };
  };
}
