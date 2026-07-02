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
    })
  ];
}
