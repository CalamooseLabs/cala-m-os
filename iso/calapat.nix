# Media-provisioned PAT → GitHub token for Nix, on the live installer.
#
# A host with a PRIVATE `github:` flake input (tci-cloud's cobblemon-initiative,
# battlestation/devbox's bookkeeper) can't even be evaluated by the installer
# without an `access-tokens` line, and that line lives in Proton Pass (item
# `nix-github-token`, see modules/nix-github-token). So when the install media
# carries a Proton Pass PAT, log in with it and fetch the line:
#
#   - /iso/calapat/pat   — injected into an ISO *file* by `build-pat-iso` (dev
#                          shell). For cloud custom-ISO uploads: a virtual CD-ROM
#                          has no partition table for a CALAPAT partition.
#   - CALAPAT partition  — appended to a USB stick by `flash-iso --with-pat`.
#
# The PAT never enters the nix store; both paths add it after the build.
#
# Where the token lands matters: install-cala-m-os's Step Four runs
# `nixos-rebuild` inside `nixos-enter`, which reads the TARGET's nix.conf and
# mounts a fresh /run, but rbinds the live /dev. So the line goes to /dev/shm,
# the live nix.conf `!include`s it, and the install-cala-m-os shim below exports
# it as NIX_USER_CONF_FILES, which the chroot inherits. (`NIX_CONFIG` is no use
# here: install-cala-m-os overwrites it with `tarball-ttl = 0`.) Nix skips a
# missing or unreadable include, so media without a PAT behave as before.
{
  inputs,
  pkgs,
  lib,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  antlers = inputs.antlers.packages.${system};

  patFile = "/iso/calapat/pat";
  tokenFile = "/dev/shm/cala-install/nix-access-tokens.conf";

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
      PAT_FILE="''${PROTON_PASS_PAT_FILE:-${patFile}}"
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
        install -d -m 0700 "$(dirname "$TOKEN_FILE")" || return 1
        (
          umask 077
          printf '%s\n' "$line" >"$TOKEN_FILE.tmp"
        ) || return 1
        mv -f "$TOKEN_FILE.tmp" "$TOKEN_FILE" || return 1
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

  # Shadows antlers' install-cala-m-os (hiPrio), so the TUI and a manual
  # `sudo install-cala-m-os <host>` both go through it.
  install-cala-m-os-shim = pkgs.writeShellApplication {
    name = "install-cala-m-os";
    text = ''
      if ! ${cala-nix-token}/bin/cala-nix-token; then
        echo "install-cala-m-os: no GitHub token from the media PAT; private flake inputs will fail to fetch." >&2
      fi
      export NIX_USER_CONF_FILES="${tokenFile}''${NIX_USER_CONF_FILES:+:$NIX_USER_CONF_FILES}"
      exec ${antlers.install-cala-m-os}/bin/install-cala-m-os "$@"
    '';
  };
in {
  environment.systemPackages = [
    cala-nix-token
    (lib.hiPrio install-cala-m-os-shim)
  ];

  # cala-installer's discover_pat (online hosts) and `proton-secrets login` both
  # honour this; a missing file falls through to the CALAPAT partition.
  environment.variables.PROTON_PASS_PAT_FILE = patFile;

  nix.extraOptions = ''
    !include ${tokenFile}
  '';

  # Fetch at boot so cala-installer's pre-install evals (secrets backend, version)
  # already see the token. Type=simple: a oneshot would hold multi-user.target
  # while it waits for the network.
  systemd.services.cala-nix-token = {
    description = "Fetch the GitHub token for private flake inputs via the media's Proton Pass PAT";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${cala-nix-token}/bin/cala-nix-token --wait";
    };
  };
}
