# nix-github-token — hand a GitHub PAT to Nix so `github:` flake INPUTS that
# point at PRIVATE repos can be fetched at eval time (`nixos-rebuild`, `nix
# flake check`, …).
#
# Why a token and not an SSH key: the `github:Owner/Repo` shorthand fetches over
# GitHub's tarball API, which for a private repo needs an `access-tokens` entry.
# SSH keys only help if the input is rewritten to `git+ssh://…`. Keeping the
# token approach means every existing `github:` URL and the flake.lock format
# stay unchanged.
#
# Delivery rides the existing backend-neutral secrets facade
# (modules/secrets/configuration.nix): the token is declared as
# `calamoose.secrets."nix-github-token"` and resolves to /run/agenix/… (offline
# hosts) or /run/proton-secrets/… (online hosts). We then `!include` that file
# into /etc/nix/nix.conf via nix.extraOptions, so the ROOT evaluator behind
# `sudo nixos-rebuild` picks it up. A missing include is non-fatal in Nix, so a
# host that hasn't been provisioned yet still builds (public inputs unaffected;
# a private fetch just fails with a clear auth error).
#
# The decrypted secret CONTENT must be a literal nix.conf directive line, e.g.:
#     access-tokens = github.com=github_pat_XXXXXXXXXXXXXXXXXXXX
# (a fine-grained PAT with Contents: Read-only on the private repo, or a classic
# token with `repo` scope). Store that whole line — not just the raw token — as
# the Proton Pass item's "secret" field (online hosts) or as the .age plaintext
# (offline hosts).
#
# Enable per host by adding "nix-github-token" to that host's extra_user_modules,
# then (offline hosts only) point `agenixFile` at the encrypted token. See the
# module README-style notes at the bottom of this file.
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.nix-github-token;
in {
  options.programs.nix-github-token = {
    enable = lib.mkEnableOption "including a GitHub PAT in nix.conf so private `github:` flake inputs can be fetched";

    # ---- online backend (Proton Pass) selectors; defaults are usually fine ----
    vaultName = lib.mkOption {
      type = lib.types.str;
      default = "Cala-M-OS";
      description = "Proton Pass vault holding the token item (online backend).";
    };
    itemTitle = lib.mkOption {
      type = lib.types.str;
      default = "nix-github-token";
      description = "Proton Pass item title for the token (online backend).";
    };
    field = lib.mkOption {
      type = lib.types.str;
      default = "secret";
      description = "Proton Pass custom field holding the `access-tokens = …` line (online backend).";
    };

    # ---- offline backend (agenix) ----
    agenixFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "./secrets/nix-github-token.age";
      description = ''
        Encrypted .age file whose plaintext is the `access-tokens = …` line.
        REQUIRED on offline (agenix) hosts; ignored on online (Proton) hosts.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Declared once through the facade; it dispatches to age.secrets or
    # services.proton-secrets per the host's calamoose.enableSecrets. Both the
    # agenix selector (agenixFile) and the Proton selectors are set — the facade
    # simply uses whichever matches the active backend, so this is safe on both.
    calamoose.secrets."nix-github-token" = {
      inherit (cfg) vaultName itemTitle field;
      agenixFile = cfg.agenixFile;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Pull the token into nix.conf. `!include` (not a normal setting) is why this
    # goes through the extraOptions escape hatch. Root-owned 0400 → readable by
    # the root evaluator, invisible to the world (unlike nix.settings.access-tokens,
    # which would bake the token into a world-readable /etc/nix/nix.conf).
    nix.extraOptions = ''
      !include ${config.calamoose.secrets."nix-github-token".path}
    '';
  };
}
