{
  config,
  pkgs,
  lib,
  cala-m-os,
  ...
}: let
  user = cala-m-os.globals.defaultUser;
  cfg = config.services.gpg-key-import;
  asc = "/run/agenix/yubigpg.asc";
  gnupgHome = "/home/${user}/.gnupg";
in {
  options.services.gpg-key-import.keyId = lib.mkOption {
    type = lib.types.str;
    default = "50D56BF0B93CA212";
    description = ''
      GPG key id used as the guard: the import is skipped when this key is already
      in ${user}'s keyring, so the oneshot is a no-op on every rebuild/boot after
      the first successful import.
    '';
  };

  # Idempotent import of the Yubikey GPG public key (agenix-provided yubigpg.asc),
  # the README "GPG Signing key" step. Runs only where secrets are enabled.
  # SSH resident keys stay manual (`ssh-keygen -K`) — they need the Yubikey + PIN.
  config = lib.mkIf config.calamoose.enableSecrets {
    systemd.services.gpg-key-import = {
      description = "Import the Yubikey GPG public key into ${user}'s keyring";
      wantedBy = ["multi-user.target"];
      after = ["agenix.service"];
      path = [pkgs.gnupg pkgs.util-linux];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Guard 1: secret not present (secrets disabled, or Yubikey absent at decrypt) — skip.
        if [ ! -r "${asc}" ]; then
          echo "${asc} not available — skipping GPG import."
          exit 0
        fi
        # Guard 2: key already imported — skip (never re-import / overwrite).
        if runuser -u ${user} -- gpg --homedir "${gnupgHome}" --list-keys "${cfg.keyId}" >/dev/null 2>&1; then
          echo "GPG key ${cfg.keyId} already in ${user}'s keyring — skipping."
          exit 0
        fi
        echo "Importing Yubikey GPG public key into ${user}'s keyring…"
        runuser -u ${user} -- gpg --homedir "${gnupgHome}" --import < "${asc}"
      '';
    };
  };
}
