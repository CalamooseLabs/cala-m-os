# Backend-neutral secrets facade.
#
# Every secret in the tree is declared once as `calamoose.secrets.<name>` with an
# `agenixFile` (for the offline/agenix backend) and a `reference` (a pass:// URI for
# the online/Proton Pass backend). Based on `calamoose._secretsBackend` (resolved
# from `calamoose.enableSecrets` in hosts/_core/options.nix) this module translates
# them to either `age.secrets.<name>` or `services.proton-secrets.secrets.<name>`.
#
# Consumers read `config.calamoose.secrets.<name>.path`, which resolves to the right
# runtime path per backend (/run/agenix/<name> or /run/proton-secrets/<name>) — so
# nothing downstream needs to know which backend is active.
#
# The agenix module is imported per-user (bare "agenix" in each user's module list)
# and self-gates; only the Proton Pass module is imported here. Both are inert unless
# their backend is selected.
{
  inputs,
  lib,
  config,
  ...
}: let
  backend = config.calamoose._secretsBackend;

  secretsRoot =
    if backend == "proton-pass"
    then "/run/proton-secrets"
    else "/run/agenix"; # agenix, or a harmless default when "none"

  cfg = config.calamoose.secrets;

  secretSubmodule = lib.types.submodule ({name, ...}: {
    options = {
      agenixFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Encrypted .age file for the offline (agenix) backend.";
      };
      reference = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "pass://SHARE_ID/ITEM_ID/password";
        description = "Proton Pass pass:// reference for the online backend.";
      };
      vaultName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Cala-M-OS";
        description = "Proton Pass vault-name selector (online backend; use with itemTitle instead of a pass:// reference).";
      };
      itemTitle = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Proton Pass item-title selector (online backend; use with vaultName).";
      };
      field = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional Proton Pass field to extract (online backend only).";
      };
      owner = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      group = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      mode = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      path = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "Runtime path to the decrypted secret for the active backend.";
      };
    };
    config.path = "${secretsRoot}/${name}";
  });

  # Only forward owner/group/mode when explicitly set, so each backend keeps its
  # own defaults (agenix + proton-secrets both default to root:root 0400).
  ownerAttrs = s:
    (lib.optionalAttrs (s.owner != null) {owner = s.owner;})
    // (lib.optionalAttrs (s.group != null) {group = s.group;})
    // (lib.optionalAttrs (s.mode != null) {mode = s.mode;});
in {
  imports = [inputs.antlers.nixosModules.proton-secrets];

  options.calamoose.secrets = lib.mkOption {
    type = lib.types.attrsOf secretSubmodule;
    default = {};
    description = "Backend-neutral secret declarations, resolved per calamoose.enableSecrets.";
  };

  options.calamoose.secretsSelfHealRestartUnits = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    example = ["multichat.service"];
    description = ''
      Systemd units to `try-restart` after the online (Proton Pass) self-heal
      successfully fetches secrets post-boot. Use this for RUNTIME consumers that
      read a secret FILE at service start (e.g. via LoadCredential) and would
      otherwise miss a value that only arrives once the network is up.
      Activation-time consumers (hashedPasswordFile, etc.) are re-applied by the
      self-heal's `switch-to-configuration` and must NOT be listed here.
    '';
  };

  config = lib.mkMerge [
    # ---- offline: agenix ----
    (lib.mkIf (backend == "agenix") {
      age.secrets = lib.mapAttrs (_name: s: {file = s.agenixFile;} // ownerAttrs s) cfg;
      assertions =
        lib.mapAttrsToList (name: s: {
          assertion = s.agenixFile != null;
          message = "calamoose.secrets.\"${name}\": agenixFile is required for the offline (agenix) backend.";
        })
        cfg;
    })

    # ---- online: Proton Pass ----
    (lib.mkIf (backend == "proton-pass") {
      services.proton-secrets = {
        enable = true;
        secrets = lib.mapAttrs (_name: s:
          (lib.optionalAttrs (s.reference != null) {reference = s.reference;})
          // (lib.optionalAttrs (s.vaultName != null) {vaultName = s.vaultName;})
          // (lib.optionalAttrs (s.itemTitle != null) {itemTitle = s.itemTitle;})
          // (lib.optionalAttrs (s.field != null) {field = s.field;})
          // ownerAttrs s)
        cfg;
      };
      assertions =
        lib.mapAttrsToList (name: s: {
          assertion = s.reference != null || (s.vaultName != null && s.itemTitle != null);
          message = "calamoose.secrets.\"${name}\": set `reference` (pass://…) or both `vaultName` and `itemTitle` for the online (proton-pass) backend.";
        })
        cfg;
      # Permit just the unfree Proton Pass CLI (server hosts don't set allowUnfree).
      nixpkgs.config.allowUnfreePredicate = lib.mkDefault (pkg: lib.getName pkg == "proton-pass-cli");

      # ---- Self-heal: fetch the online secrets once the network is up ----
      # With systemd stage-1 (boot.initrd.systemd.enable, the default here) NixOS
      # runs `activate` ONLY inside the initrd, which has no network — so the
      # Proton fetch there always fails and the ramfs secrets (/run/proton-secrets/*)
      # start every boot empty, and `activate` is NOT re-run in stage-2. Without
      # this, secrets are populated only by a manual `nixos-rebuild switch` while
      # online. This oneshot re-runs activation once network-online is reached:
      # `switch-to-configuration test` re-executes the Proton fetch (now WITH
      # network) AND the `users` snippet, so both the secret files and their
      # activation-time consumers (e.g. hashedPasswordFile) are populated with no
      # manual step. Runtime consumers that read a secret file at start
      # (LoadCredential, etc.) are bounced via secretsSelfHealRestartUnits.
      #
      # It only acts when a secret is actually missing (i.e. the initrd couldn't
      # fetch), retries a few times to ride out flaky first-boot DHCP, and never
      # fails the boot. Same-generation `switch-to-configuration` computes zero
      # unit changes, so it re-runs activation without restarting the live session.
      systemd.services.proton-secrets-selfheal = lib.mkIf (cfg != {}) {
        description = "Fetch online secrets once the network is up (initrd activation has none)";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "300";
        };
        script = let
          paths = lib.concatMapStringsSep " " (s: lib.escapeShellArg s.path) (lib.attrValues cfg);
          systemctl = "${config.systemd.package}/bin/systemctl";
          restarts =
            lib.concatMapStringsSep "\n"
            (u: "${systemctl} try-restart ${lib.escapeShellArg u} || true")
            config.calamoose.secretsSelfHealRestartUnits;
        in ''
          set -u
          _ps_missing() { for p in ${paths}; do [ -e "$p" ] || return 0; done; return 1; }
          if ! _ps_missing; then
            echo "[proton-secrets-selfheal] all secrets already present; nothing to do"
            exit 0
          fi
          _n=0
          while [ "$_n" -lt 5 ]; do
            _n=$((_n + 1))
            echo "[proton-secrets-selfheal] attempt $_n: re-running activation with network up..."
            /run/current-system/bin/switch-to-configuration test || true
            if ! _ps_missing; then
              echo "[proton-secrets-selfheal] secrets populated."
              ${restarts}
              exit 0
            fi
            sleep 5
          done
          echo "[proton-secrets-selfheal] WARNING: secrets still missing after $_n attempts (check network / Proton session)." >&2
          exit 0
        '';
      };
    })
  ];
}
