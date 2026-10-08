# build-pat-iso — the installer ISO as a standalone .iso FILE carrying a Proton
# Pass PAT at /calapat/pat, for a cloud provider's custom-ISO slot (Hetzner Cloud
# mounts it as a virtual CD-ROM, so flash-iso's appended CALAPAT partition would
# never be seen). The ISO is built clean, then a copy is patched with xorriso
# replaying the original boot records; the nix store never sees the PAT. On boot,
# iso/calapat.nix logs in with it and fetches the GitHub token for Nix.
#
#   nix develop -c build-pat-iso (--vault NAME | --shared-vault) [--pat-file FILE]
#                                [--out FILE] [--force] [--no-check] [--item TITLE] [--field NAME]
{
  writeShellApplication,
  xorriso,
  coreutils,
  findutils,
  diffutils,
  git,
  gnused,
  gnugrep,
  proton-pass-cli,
}:
writeShellApplication {
  name = "build-pat-iso";
  runtimeInputs = [xorriso coreutils findutils diffutils git gnused gnugrep proton-pass-cli];
  text = ''
    die() {
      echo "build-pat-iso: $*" >&2
      exit 1
    }
    usage() {
      cat <<'EOF'
    usage: build-pat-iso (--vault NAME | --shared-vault) [--pat-file FILE] [--out FILE]
                         [--force] [--no-check] [--item TITLE] [--field NAME]
      --vault NAME     Proton vault holding the token item. Grant the PAT ONLY this
                       vault: anyone with the ISO can use the PAT.
      --shared-vault   read the shared Cala-M-OS vault instead (the PAT then exposes
                       whatever it is granted there; avoid for third-party uploads)
      --item/--field   token item + field (default: nix-github-token / secret)
      --pat-file FILE  read the Proton Pass PAT from FILE instead of prompting
      --out FILE       output ISO (default: ~/cala-m-os-installer-pat.iso)
      --force          overwrite an existing output file
      --no-check       skip the pre-flight Proton Pass login + token-item read
    EOF
    }

    # Mirrors canonical() in iso/calapat.nix: the installer only accepts this.
    canonical() {
      local rest
      case "$1" in
        github_pat_* | ghp_*) rest="github.com=$1" ;;
        access-tokens*) rest=$(printf '%s' "$1" | sed -E 's/^access-tokens[[:space:]]*=[[:space:]]*//') ;;
        *) return 1 ;;
      esac
      printf '%s' "$rest" | grep -Eq '^[^[:space:]=]+=[^[:space:]]+([[:space:]]+[^[:space:]=]+=[^[:space:]]+)*$'
    }

    PAT_FILE=""
    OUT="$HOME/cala-m-os-installer-pat.iso"
    FORCE=0
    CHECK=1
    SHARED=0
    VAULT=""
    ITEM=""
    FIELD=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --pat-file) PAT_FILE="''${2:?--pat-file needs a path}"; shift 2 ;;
        --out) OUT="''${2:?--out needs a path}"; shift 2 ;;
        --force) FORCE=1; shift ;;
        --no-check) CHECK=0; shift ;;
        --vault) VAULT="''${2:?--vault needs a name}"; shift 2 ;;
        --shared-vault) SHARED=1; shift ;;
        --item) ITEM="''${2:?--item needs a title}"; shift 2 ;;
        --field) FIELD="''${2:?--field needs a name}"; shift 2 ;;
        -h | --help) usage; exit 0 ;;
        *) usage >&2; exit 64 ;;
      esac
    done
    if [ -z "$VAULT" ] && [ "$SHARED" -ne 1 ]; then
      usage >&2
      die "pass --vault NAME (a vault holding only the token item, the PAT granted just that) or --shared-vault."
    fi
    [ -z "$VAULT" ] || [ "$SHARED" -ne 1 ] || die "--vault and --shared-vault are mutually exclusive."

    FLAKE="''${BUILD_PAT_ISO_FLAKE:-$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || echo "$PWD")}"
    [ -f "$FLAKE/flake.nix" ] || die "no flake.nix in $FLAKE; run from the Cala-M-OS checkout or set BUILD_PAT_ISO_FLAKE=/path/to/it."
    FLAKE=$(realpath "$FLAKE")
    OUT=$(realpath -m "$OUT")
    [ ! -d "$OUT" ] || die "--out must be a file path, not a directory ($OUT)."
    case "$OUT" in
      "$FLAKE" | "$FLAKE"/*) die "refusing to write a PAT-bearing ISO inside the flake ($FLAKE); pick --out elsewhere." ;;
    esac
    [ -d "$(dirname "$OUT")" ] || die "output directory $(dirname "$OUT") does not exist."
    if [ -e "$OUT" ] && [ "$FORCE" -ne 1 ]; then
      die "$OUT already exists (use --force to overwrite)."
    fi

    if [ -n "$PAT_FILE" ]; then
      [ -r "$PAT_FILE" ] || die "cannot read PAT file '$PAT_FILE'."
      PAT=$(tr -d '\r\n' <"$PAT_FILE")
    else
      read -rsp "Paste the Proton Pass PAT (pst_...::key): " PAT ||
        [ -n "$PAT" ] || die "no PAT on stdin (use --pat-file for non-interactive runs)."
      echo
    fi
    [ -n "$PAT" ] || die "empty PAT."
    case "$PAT" in
      *[[:space:]]*) die "the PAT contains whitespace; check what was pasted." ;;
    esac

    umask 077
    WORK=$(mktemp -d)
    PARTIAL="$OUT.partial"
    trap 'rm -rf "$WORK"; rm -f "$PARTIAL"' EXIT

    # Do what the installer will do (iso/calapat.nix), from here, before anything
    # ships: a typo'd PAT or a vault the PAT can't see would otherwise only show
    # up on the cloud box, a provider round trip later. Throwaway session.
    if [ "$CHECK" -eq 1 ]; then
      echo "Checking the PAT against Proton Pass..."
      unset PROTON_PASS_PAT_FILE
      export PROTON_PASS_SESSION_DIR="$WORK/session" PROTON_PASS_KEY_PROVIDER=fs PROTON_PASS_NO_UPDATE_CHECK=1
      export PROTON_PASS_AGENT_REASON="Cala-M-OS build-pat-iso: check the PAT can read the Nix GitHub token"
      mkdir "$PROTON_PASS_SESSION_DIR"
      V="''${VAULT:-Cala-M-OS}" I="''${ITEM:-nix-github-token}" F="''${FIELD:-secret}"
      if ! err=$(PROTON_PASS_PERSONAL_ACCESS_TOKEN="$PAT" pass-cli login </dev/null 2>&1 >/dev/null); then
        { printf '%s\n' "$err" | grep -v '^[[:space:]]*$' || true; } | tail -n2 | sed -E "s/pst_[^[:space:]']{8,}/pst_<redacted>/g" >&2
        die "Proton Pass rejected the PAT (re-copy it, or --no-check to skip)."
      fi
      value=$(pass-cli item view --vault-name "$V" --item-title "$I" --field "$F" 2>/dev/null || true)
      pass-cli logout --force >/dev/null 2>&1 || true
      value=$(printf '%s\n' "$value" | tr -d '\r' | sed -n '/[^[:space:]]/{s/^[[:space:]]*//;s/[[:space:]]*$//;p;q}')
      if [ -z "$value" ]; then
        die "the PAT logged in but can't read '$I' / '$F' in vault '$V' (is the PAT granted that whole vault?)."
      fi
      canonical "$value" || die "item '$I' doesn't hold an 'access-tokens = host=token' line or a GitHub token."
      unset value
      echo "PAT OK: it can read the GitHub token item."
    fi

    echo "Building the installer ISO..."
    BASE=$(nix build "$FLAKE#nixosConfigurations.iso.config.system.build.isoImage" \
      --no-link --print-out-paths --print-build-logs)
    ISO=$(find "$BASE/iso" -maxdepth 1 -name '*.iso' | head -n1)
    [ -n "$ISO" ] || die "no .iso under $BASE/iso."
    echo "Base ISO: $ISO"

    mkdir "$WORK/calapat"
    printf '%s' "$PAT" >"$WORK/calapat/pat"
    [ -z "$VAULT" ] || printf '%s' "$VAULT" >"$WORK/calapat/vault"
    [ -z "$ITEM" ] || printf '%s' "$ITEM" >"$WORK/calapat/item"
    [ -z "$FIELD" ] || printf '%s' "$FIELD" >"$WORK/calapat/field"
    unset PAT

    # Root-only on the live system (Rock Ridge perms); root traverses 0500.
    # -boot_image any replay (last, after the file edits) re-emits the original
    # El Torito (BIOS + EFI), isohybrid MBR and GPT; no_emul_toc + padding
    # included keep the original single-session layout; replay doesn't carry
    # Joliet, so ask for it. xorriso refuses a non-empty -outdev.
    rm -f "$PARTIAL"
    xorriso -abort_on FAILURE \
      -indev "$ISO" -outdev "$PARTIAL" \
      -joliet on \
      -map "$WORK/calapat" /calapat \
      -chown_r 0 /calapat -- \
      -chgrp_r 0 /calapat -- \
      -chmod_r 0400 /calapat -- \
      -chmod 0500 /calapat -- \
      -boot_image any replay \
      -compliance no_emul_toc \
      -padding included \
      2>"$WORK/xorriso.log" || {
      cat "$WORK/xorriso.log" >&2
      die "xorriso failed."
    }

    # Verify before handing it over: the PAT reads back, and the boot setup and
    # volume ID match the original.
    xorriso -osirrox on -indev "$PARTIAL" -extract /calapat/pat "$WORK/readback" 2>/dev/null ||
      die "could not read /calapat/pat back from the new image."
    cmp -s "$WORK/calapat/pat" "$WORK/readback" || die "PAT readback mismatch."
    boot_summary() {
      xorriso -indev "$1" -report_el_torito plain -report_system_area plain -pvd_info 2>/dev/null |
        grep -E '^(Volume Id|System area summary|El Torito boot img|El Torito img (path|opts)|MBR partition +:|MBR partition path|GPT partname local|GPT partition path)' |
        sed -E -e 's/^(MBR partition +: +[0-9]+ +0x[0-9a-f]+ +0x[0-9a-f]+).*/\1/' -e 's/[[:space:]]+[0-9]+[[:space:]]*$//' || true
    }
    boot_summary "$ISO" >"$WORK/boot.orig"
    if ! grep -q "^Volume Id" "$WORK/boot.orig" || ! grep -q "^El Torito boot img" "$WORK/boot.orig"; then
      die "could not read the original ISO's boot records to compare against."
    fi
    boot_summary "$PARTIAL" >"$WORK/boot.new"
    if ! diff -u "$WORK/boot.orig" "$WORK/boot.new" >"$WORK/boot.diff"; then
      cat "$WORK/boot.diff" >&2
      die "boot records differ from the original ISO; not trusting the copy."
    fi

    chmod 600 "$PARTIAL"
    mv -fT "$PARTIAL" "$OUT"
    echo
    echo "Wrote $OUT ($(du -h "$OUT" | cut -f1))"
    echo "sha256: $(sha256sum "$OUT" | cut -d' ' -f1)"
    echo
    echo "This file holds a live Proton Pass PAT. Revoke it once the install is done (unless"
    echo "an online-secrets host was installed from it: the installer seeds the PAT there),"
    echo "and delete the ISO from the share and the provider afterwards."
  '';
}
