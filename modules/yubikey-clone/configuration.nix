{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.yubikey-clone;
in {
  # yubikey-clone ships from the antlers scripts collection. This module keeps a
  # `programs.yubikey-clone` facade (matching the gpg-key-import / ssh-key-import
  # pattern) and delegates the install to antlers.
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  options.programs.yubikey-clone = {
    enable = lib.mkEnableOption "the yubikey-clone command (provision a spare Yubikey: diagnose + clone the OpenPGP git-signing/SSH keys, generate fresh FIDO2 + age identities)";

    keyId = lib.mkOption {
      type = lib.types.str;
      default = "50D56BF0B93CA212";
      description = "OpenPGP key id the spare should mirror (defaults to the Cala-M-OS Yubikey key).";
    };
  };

  # Unlike gpg-key-import this is NOT gated on calamoose.enableSecrets: it is an
  # on-demand provisioning tool and can seed the public key from the live keyring
  # when /run/agenix/yubigpg.asc is absent.
  config = lib.mkIf cfg.enable {
    programs.antlers-scripts = {
      enable = true;
      yubikey-clone = {
        enable = true;
        keyId = cfg.keyId;
        # publicKeyFile / sshBackupKeyName / fido2Application / configPath keep
        # their antlers defaults (/run/agenix/yubigpg.asc, backup_id_ed25519_sk,
        # ssh:, /etc/nixos).
      };
    };
  };
}
