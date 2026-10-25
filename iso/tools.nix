# The live installer's own tools, as plain derivations — usable from the NixOS
# installer modules (./calapat.nix, ./installer.nix) AND as the flake package
# `packages.<system>.installer-tools`, which is what cala-installer's "Update
# the installer" menu entry pulls from the flake: an old ISO or stick then runs
# today's TUI and backend without being reflashed.
#
#   cala-installer      antlers' gum TUI (scripts/cala-installer.sh)
#   install-cala-m-os   the token-aware SHIM: fetches the GitHub token from the
#                       media's Proton PAT (cala-nix-token), exports it for the
#                       install's nixos-enter, then execs antlers' backend
#   cala-nix-token      the token fetcher itself (also the image's boot service)
#   bundle              all three in one bin/ (symlinkJoin) — the update target
#
# antlers' scripts are built straight from their package.nix files against THIS
# package set, so the same code serves the aarch64 image too (antlers' own
# packages.<system> is x86_64-only; its overlay is not used here).
#
# mediaDir is only the baked default: the image exports CALA_INSTALLER_MEDIA_DIR
# so a bundle built from the flake works on either image (see cala-nix-token).
{
  pkgs,
  inputs,
  lib ? pkgs.lib,
  mediaDir ? "/iso/calapat",
}: let
  tokenFile = "/dev/shm/cala-install/nix-access-tokens.conf";

  antlersScripts = pkgs.callPackages (inputs.antlers + "/flakes/scripts/package.nix") {};
  backend = antlersScripts.install-cala-m-os;

  cala-nix-token = pkgs.writeShellApplication {
    name = "cala-nix-token";
    runtimeInputs = [pkgs.proton-pass-cli pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.util-linux pkgs.systemd];
    text = ''
      # Usage: cala-nix-token [--wait] [--force]
      #   --wait   retry with backoff until it succeeds (boot service; the network
      #            may come up late, e.g. after nmtui); gives up on errors that
      #            retrying can't fix (bad PAT, missing grant, bad item)
      #   --force  refetch even if the token file already exists
      # Exits 0 when there is no PAT on the media (nothing to do).
      TOKEN_FILE=${lib.escapeShellArg tokenFile}
      # The image exports CALA_INSTALLER_MEDIA_DIR (iso/calapat.nix), so one build
      # of this package serves both the ISO (/iso/calapat) and the kexec image
      # (/var/lib/cala-reinstall); the baked value is only the fallback.
      MEDIA_DIR=''${CALA_INSTALLER_MEDIA_DIR:-${lib.escapeShellArg mediaDir}}
      PAT_FILE="''${PROTON_PASS_PAT_FILE:-$MEDIA_DIR/pat}"
      # Same selectors as modules/nix-github-token; media files may override them.
      VAULT="''${CALA_NIX_TOKEN_VAULT:-Cala-M-OS}"
      ITEM="''${CALA_NIX_TOKEN_ITEM:-nix-github-token}"
      FIELD="''${CALA_NIX_TOKEN_FIELD:-secret}"
      # A private, per-attempt session: cala-installer's own store (seeded onto
      # online targets) is left exactly as it was, and a stale session can't
      # block the next login ("Already authenticated").
      export PROTON_PASS_SESSION_DIR=/run/cala-nix-token/session
      export PROTON_PASS_KEY_PROVIDER=fs
      export PROTON_PASS_NO_UPDATE_CHECK=1
      # Required for item reads when the PAT was created as an AI-agent token;
      # ignored for a plain PAT.
      export PROTON_PASS_AGENT_REASON="''${PROTON_PASS_AGENT_REASON:-Cala-M-OS installer: read the Nix GitHub token}"

      log() { echo "cala-nix-token: $*" >&2; }

      WAIT=0
      FORCE=0
      for arg in "$@"; do
        case "$arg" in
          --wait) WAIT=1 ;;
          --force) FORCE=1 ;;
          *)
            log "unknown argument '$arg'"
            exit 64
            ;;
        esac
      done

      if [ "$(id -u)" -ne 0 ]; then
        log "must run as root."
        exit 1
      fi

      have_token() { [ -s "$TOKEN_FILE" ] && grep -q '^access-tokens' "$TOKEN_FILE"; }
      if [ "$FORCE" -eq 0 ] && have_token; then exit 0; fi

      # Last two non-blank lines of pass-cli's stderr, PAT redacted.
      show() { printf '%s\n' "$1" | grep -v '^[[:space:]]*$' | tail -n2 | sed -E "s/pst_[^[:space:]']{8,}/pst_<redacted>/g" >&2 || true; }

      # Canonical `access-tokens = host=token …` from the item value. A malformed
      # line (e.g. no spaces round the `=`) makes EVERY nix command fail, echoing
      # the whole line — token included — in the error, so never write one.
      canonical() {
        local rest
        case "$1" in
          # The item should hold the whole directive, but accept a bare token.
          github_pat_* | ghp_*) rest="github.com=$1" ;;
          access-tokens*) rest=$(printf '%s' "$1" | sed -E 's/^access-tokens[[:space:]]*=[[:space:]]*//') ;;
          *) return 1 ;;
        esac
        printf '%s' "$rest" | grep -Eq '^[^[:space:]=]+=[^[:space:]]+([[:space:]]+[^[:space:]=]+=[^[:space:]]+)*$' || return 1
        printf 'access-tokens = %s\n' "$rest"
      }

      write_token() {
        install -d -m 0700 "$(dirname "$TOKEN_FILE")" || return 1
        (
          umask 077
          printf '%s\n' "$1" >"$TOKEN_FILE.tmp"
        ) || return 1
        mv -f "$TOKEN_FILE.tmp" "$TOKEN_FILE" || return 1
      }

      # A ready-made token on the media (cala-reinstall carries the host's own):
      # no Proton round trip needed.
      if [ -r "$MEDIA_DIR/nix-access-tokens.conf" ]; then
        value=$(sed -n '/[^[:space:]]/{s/^[[:space:]]*//;s/[[:space:]]*$//;p;q}' "$MEDIA_DIR/nix-access-tokens.conf")
        if line=$(canonical "$value") && write_token "$line"; then
          log "GitHub access token for Nix taken from $MEDIA_DIR/nix-access-tokens.conf."
          exit 0
        fi
        log "ignoring $MEDIA_DIR/nix-access-tokens.conf: not an 'access-tokens = host=token' line."
      fi

      # Optional vault/item/field files next to the PAT (build-pat-iso --vault …).
      read_overrides() {
        local d="$1"
        if [ -r "$d/vault" ]; then VAULT=$(cat "$d/vault"); fi
        if [ -r "$d/item" ]; then ITEM=$(cat "$d/item"); fi
        if [ -r "$d/field" ]; then FIELD=$(cat "$d/field"); fi
      }

      PAT=""
      if [ -r "$PAT_FILE" ]; then
        PAT=$(cat "$PAT_FILE")
        read_overrides "$(dirname "$PAT_FILE")"
      else
        udevadm settle --timeout=5 2>/dev/null || true
        dev=$(blkid -L CALAPAT 2>/dev/null || true)
        if [ -n "$dev" ]; then
          mp=$(mktemp -d)
          # A stick that is also the boot medium is held whole-disk, so a plain
          # mount of its partition fails EBUSY; a loop mount gets around that.
          if mount -o ro "$dev" "$mp" 2>/dev/null || mount -o ro,loop "$dev" "$mp" 2>/dev/null; then
            if [ -r "$mp/pat" ]; then
              PAT=$(cat "$mp/pat")
              read_overrides "$mp"
            else
              log "CALAPAT partition $dev holds no 'pat' file."
            fi
            umount "$mp" 2>/dev/null || true
          else
            log "could not mount CALAPAT partition $dev."
          fi
          rmdir "$mp" 2>/dev/null || true
        fi
      fi
      if [ -z "$PAT" ]; then
        log "no Proton Pass PAT on the install media; nothing to do."
        exit 0
      fi

      # Returns 0 on success, 1 for errors worth retrying (network), 2 for ones
      # retrying can't fix. pass-cli is called directly, not via proton-secrets,
      # whose session probe (`pass-cli test`) is gone from pass-cli 2.2.4+.
      attempt() {
        local value line err
        rm -rf "$PROTON_PASS_SESSION_DIR"
        install -d -m 0700 /run/cala-nix-token "$PROTON_PASS_SESSION_DIR" || return 1
        # The env var (not --pat) keeps the PAT out of argv.
        if ! err=$(PROTON_PASS_PERSONAL_ACCESS_TOKEN="$PAT" pass-cli login </dev/null 2>&1 >/dev/null); then
          log "Proton Pass login with the media PAT failed:"
          show "$err"
          case "$err" in
            *"invalid, expired or has been deleted"* | *"Failed to parse personal access token"* | *"Failed to decode personal access token"*) return 2 ;;
          esac
          return 1
        fi
        if ! value=$(pass-cli item view --vault-name "$VAULT" --item-title "$ITEM" --field "$FIELD" 2>/run/cala-nix-token/view.err); then
          log "logged in, but could not read field '$FIELD' of item '$ITEM' in vault '$VAULT' (is the PAT granted that whole vault?):"
          show "$(cat /run/cala-nix-token/view.err)"
          pass-cli logout --force >/dev/null 2>&1 || true
          return 2
        fi
        pass-cli logout --force >/dev/null 2>&1 || true
        # First non-blank line, trimmed.
        value=$(printf '%s\n' "$value" | tr -d '\r' | sed -n '/[^[:space:]]/{s/^[[:space:]]*//;s/[[:space:]]*$//;p;q}')
        if ! line=$(canonical "$value"); then
          log "item '$ITEM' doesn't hold an 'access-tokens = host=token' line or a GitHub token; not using it."
          return 2
        fi
        write_token "$line" || return 1
        log "GitHub access token for Nix fetched from Proton Pass ('$VAULT' / '$ITEM')."
      }

      # One attempt at a time: the boot service and the install-cala-m-os shim
      # can race, and they share the session dir.
      locked_attempt() {
        local rc=0
        exec 9>/run/cala-nix-token.lock
        flock 9
        if [ "$FORCE" -eq 0 ] && have_token; then
          rc=0
        else
          attempt || rc=$?
        fi
        exec 9>&-
        return "$rc"
      }

      if [ "$WAIT" -eq 0 ]; then
        locked_attempt
        exit $?
      fi
      delay=5
      while :; do
        rc=0
        locked_attempt || rc=$?
        case "$rc" in
          0) exit 0 ;;
          2)
            log "giving up; retrying won't fix that. Fix it, then run: sudo cala-nix-token"
            exit 1
            ;;
        esac
        sleep "$delay"
        delay=$((delay * 2 > 60 ? 60 : delay * 2))
      done
    '';
  };

  # Shadows antlers' install-cala-m-os (hiPrio on the image; first on PATH after
  # an update), so the TUI and a manual `sudo install-cala-m-os <host>` both go
  # through it.
  install-cala-m-os = pkgs.writeShellApplication {
    name = "install-cala-m-os";
    text = ''
      if ! ${cala-nix-token}/bin/cala-nix-token; then
        echo "install-cala-m-os: no GitHub token from the media PAT; private flake inputs will fail to fetch." >&2
      fi
      export NIX_USER_CONF_FILES="${tokenFile}''${NIX_USER_CONF_FILES:+:$NIX_USER_CONF_FILES}"
      exec ${backend}/bin/install-cala-m-os "$@"
    '';
  };
in {
  inherit tokenFile antlersScripts backend cala-nix-token install-cala-m-os;
  cala-installer = antlersScripts.cala-installer;

  # What `cala-installer` → "Update the installer" builds and re-launches from.
  bundle = pkgs.symlinkJoin {
    name = "cala-installer-tools";
    paths = [antlersScripts.cala-installer install-cala-m-os cala-nix-token];
    meta.description = "Cala-M-OS live-installer tools: cala-installer, the token-aware install-cala-m-os, cala-nix-token";
  };
}
