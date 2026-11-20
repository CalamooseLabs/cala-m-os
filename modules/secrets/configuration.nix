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
#
# ── The online backend, from power-on ───────────────────────────────────────
# Online secrets live in a ramfs, so every boot starts without them, and the
# boot-time activation cannot fetch them: it runs before there is a network (on
# a systemd stage-1 host inside the initrd, where the fetch is skipped outright).
# (The agenix backend has the same shape of problem — no pcscd at activation
# time — solved by agenix-rerun in modules/agenix.) What brings them back is
# antlers' services.proton-secrets (flakes/proton-secrets in that repo: its
# module header and README are the reference), nothing defined in this file:
#
#   proton-secrets-restore.service  only with services.proton-secrets.cache.enable
#       (a host's choice; broadcast sets it). Before sysinit.target, no network:
#       links the sealed last-known-good copies of the secrets, so a service
#       finds its files on its first start.
#   proton-secrets-fetch.service    after network-online.target: fetches every
#       secret on its own and retries a temporary failure (Proton unreachable,
#       5xx/429) with back-off for as long as it takes. It stops, and shows as
#       failed, only on exit 78 — something a human has to fix: the PAT was
#       rejected, there is no session and no PAT, a required field is missing or
#       blank, or its vault is not visible to the PAT.
#   nixos-rebuild switch            runs the same fetch from the activation
#       script; services.proton-secrets.failClosed decides whether a failed one
#       aborts the switch (the default) or keeps the previous values and warns.
#
# A secret that cannot be fetched keeps the value that is linked (or cached)
# while the others are installed, so /run/proton-secrets being there does NOT
# mean every secret is in it — test the file you need. When no value changed
# nothing is touched; otherwise only the `restartUnits` of the secrets whose
# content changed are restarted.
#
# What the last fetch did is in /run/proton-secrets.status (JSON, no secret
# material) and in the unit's journal. On the box, as root:
#   proton-secrets doctor    session files, session probe, PAT file, the last
#                            fetch per secret, the cache — prints no secret
#   proton-secrets repair    re-create the session from the PAT
#   proton-secrets refresh   run the fetch unit now and print how it went
# The runbook for "a service has no secret after boot" is in
# wiki/Secrets-and-Security.md.
#
# ── Consumers are NOT ordered onto the fetch unit ───────────────────────────
# A service that reads a secret file when it starts (LoadCredential=) is listed
# in that secret's `restartUnits` and gets no After=, Wants= or Requires= on
# proton-secrets-fetch.service — not from this module and not from its own:
#   - After= makes it wait for the first fetch run to END, and one run may take
#     minutes when Proton is slow. On a host with the cache its files are there
#     from the restore, before any service starts, and it must come up on them at
#     once. On a host without it the first start fails on the missing file and
#     the service's own restart policy retries until the fetch has linked it —
#     and the fetch then restarts it anyway, whether it is still retrying or has
#     landed in `failed`.
#   - Wants=/Requires= are worse: every start of the consumer, each round of a
#     restart loop included, queues a start of the fetch unit, which runs it at
#     once and throws its back-off away.
# So such a service needs nothing but a restart policy that does not give up.
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
      restartUnits = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["multichat.service"];
        description = ''
          Systemd units to restart when THIS secret's content changed (the first
          time it appears included) — for services that read the file when they
          start, e.g. through LoadCredential=. Online (Proton Pass) backend
          only: forwarded to services.proton-secrets.secrets.<name>.restartUnits,
          where the fetch restarts just the units that are active, starting or
          failed and leaves one somebody stopped alone. Do not also order the
          unit onto proton-secrets-fetch.service (see the header of
          modules/secrets/configuration.nix).

          No effect on the offline (agenix) backend: there a consumer that needs
          its secret at boot orders itself after agenix-rerun.service
          (modules/agenix).
        '';
      };
      optional = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          A secret the host can run without. Online (Proton Pass) backend only:
          forwarded to services.proton-secrets.secrets.<name>.optional, where a
          failure to fetch it is reported (journal and status file) but does not
          fail the fetch unit or a failClosed switch; the previous (or cached)
          value is kept all the same.

          No effect on the offline (agenix) backend.
        '';
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

  # Accounts whose password comes from a secret of the active backend.
  passwordFromSecret = lib.attrNames (lib.filterAttrs
    (_: u: u.hashedPasswordFile != null && lib.hasPrefix "${secretsRoot}/" u.hashedPasswordFile)
    config.users.users);
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
          // {inherit (s) optional restartUnits;}
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

      # hashedPasswordFile on an online host. NixOS applies password files in the
      # `users` activation snippet. During a switch that snippet runs after the
      # fetch (the antlers module orders it so) and sees the file. At boot the
      # activation runs before the network — and before systemd starts the
      # restore unit — so the file is not there, and nothing re-runs the snippet
      # once the secrets have arrived. With users.mutableUsers = true (every
      # online host today) that takes nobody's password away: the file is only
      # applied to an account that has no /etc/shadow entry yet, and an
      # existing entry is left as it is — so the secret seeds the password of
      # an account that is created while the file is readable, and never
      # changes one afterwards. (On `ai` that moment does not come: its root is
      # a tmpfs that keeps no /etc/shadow, so every boot creates the accounts
      # anew, before the file exists, and hub has no password there; it is
      # logged in on the console automatically and sudo asks for none.) With
      # mutableUsers = false NixOS rewrites every declared account's password
      # on each activation, and with the file missing that password is a locked
      # one: such an account would lose its password at every boot until the
      # next switch. Say so at eval time rather than lock somebody out.
      warnings = lib.optional (!config.users.mutableUsers && passwordFromSecret != []) ''
        calamoose.secrets (online backend): users.mutableUsers is false and hashedPasswordFile of ${lib.concatStringsSep ", " passwordFromSecret} points into ${secretsRoot}. That file does not exist yet when the boot-time activation applies passwords (it runs before the network; the secrets are fetched afterwards), so every boot would leave the account locked until the next `nixos-rebuild switch`. Keep users.mutableUsers = true on online hosts, or take that password from somewhere that exists at boot.
      '';
    })
  ];
}
