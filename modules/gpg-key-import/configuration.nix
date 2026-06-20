{
  config,
  pkgs,
  lib,
  cala-m-os,
  ...
}: let
  user = cala-m-os.globals.defaultUser;
  cfg = config.programs.gpg-key-import;
  asc = "/run/agenix/yubigpg.asc";

  # Manual, idempotent import of the Yubikey GPG public key (agenix-provided
  # yubigpg.asc) — the README "GPG Signing key" step, as a command you run when
  # you want it rather than a boot service. The secret is root-readable only, so
  # we read it through sudo and pipe it into *your* keyring.
  importer = pkgs.writeShellApplication {
    name = "gpg-key-import";
    runtimeInputs = [pkgs.gnupg pkgs.coreutils];
    text = ''
      if [ "$(id -u)" -eq 0 ]; then
        echo "Run gpg-key-import as your user, not root — the key imports into the invoking user's keyring." >&2
        exit 1
      fi

      ASC=${lib.escapeShellArg asc}
      KEY_ID=${lib.escapeShellArg cfg.keyId}

      read_asc() {
        if [ -r "$ASC" ]; then cat "$ASC"; else sudo cat "$ASC"; fi
      }

      if ! { [ -r "$ASC" ] || sudo test -r "$ASC"; }; then
        echo "$ASC not available — is enableSecrets on and the Yubikey present at boot? Skipping." >&2
        exit 0
      fi

      if gpg --list-keys "$KEY_ID" >/dev/null 2>&1; then
        echo "GPG key $KEY_ID already in your keyring — nothing to do."
        exit 0
      fi

      echo "Importing Yubikey GPG public key ($KEY_ID) into your keyring…"
      read_asc | gpg --import
      echo "Done. Verify with: gpg --list-keys $KEY_ID"
    '';
  };
in {
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
  # SSH resident keys are handled separately by `ssh-key-import`.
  config = lib.mkIf (cfg.enable && config.calamoose.enableSecrets) {
    environment.systemPackages = [importer];
  };
}
