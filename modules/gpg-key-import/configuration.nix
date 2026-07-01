{
  inputs,
  config,
  lib,
  cala-m-os,
  ...
}: let
  user = cala-m-os.globals.defaultUser;
  cfg = config.programs.gpg-key-import;
in {
  # gpg-key-import now ships from the antlers scripts collection. This module
  # keeps the `programs.gpg-key-import` facade and the same
  # `enable && calamoose.enableSecrets` gate, delegating the install to antlers.
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  options.programs.gpg-key-import = {
    enable = lib.mkEnableOption "the gpg-key-import command (import the Yubikey GPG public key into your keyring on demand)";

    keyId = lib.mkOption {
      type = lib.types.str;
      default = "50D56BF0B93CA212";
      description = ''
        GPG key id used as the guard: `gpg-key-import` is a no-op when this key is
        already in ${user}'s keyring, so it is safe to re-run.
      '';
    };
  };

  # Ship the command only when explicitly enabled AND secrets (the yubigpg.asc
  # secret) exist — without the secret there is nothing to import.
  config = lib.mkIf (cfg.enable && config.calamoose._secretsEnabled) {
    programs.antlers-scripts = {
      enable = true;
      gpg-key-import = {
        enable = true;
        keyId = cfg.keyId;
        # Point at the backend-neutral path (agenix -> /run/agenix, online ->
        # /run/proton-secrets) instead of the antlers default of /run/agenix.
        keyFile = config.calamoose.secrets."yubigpg.asc".path;
      };
    };
  };
}
