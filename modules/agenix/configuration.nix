{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  isAgenix = config.calamoose._secretsBackend == "agenix";

  # agenix runs this as `ageBin --decrypt -i <stub> ... -o <tmp> <file>`. Go age
  # tries the -i identities strictly in order and aborts on the first one whose
  # YubiKey can't be opened (with no tty the plugin's "insert key" question is
  # answered `fail`; with one it blocks on "Please insert YubiKey with serial
  # ..."), so with server.key listed first no other recipient key ever got a turn
  # (devbox's nano, the backup in a rebuilt homelab). Pass only the identities
  # whose YubiKey is connected: stubs are deterministic, so `age-plugin-yubikey
  # --identity` prints the committed AGE-PLUGIN-YUBIKEY-1... line of each one. A
  # connected key that isn't a recipient of a file then fails fast with "no
  # identity matched any of the recipients" instead of prompting for an absent
  # key. Without pcscd (stage-2 activation runs before systemd; an install chroot
  # without the installer's socket, see iso/tools.nix) no key can be opened at
  # all and the plugin would blame whichever serial is first, so say so instead.
  # If listing the keys itself fails, fall back to the full list.
  ageWrapper = pkgs.writeShellScript "agenix-age" ''
    set -u
    export PATH="$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey pkgs.gnugrep pkgs.gnused pkgs.coreutils]}"

    sock="''${PCSCLITE_CSOCK_NAME:-/run/pcscd/pcscd.comm}"
    if [ ! -S "$sock" ]; then
      echo "age: pcscd is not reachable ($sock is missing), so no YubiKey can be used yet; agenix-rerun.service decrypts once pcscd is up." >&2
      exit 1
    fi

    if ! listing=$(age-plugin-yubikey --identity 2>/dev/null); then
      exec ${pkgs.age}/bin/age "$@"
    fi
    connected=$(printf '%s\n' "$listing" | grep '^AGE-PLUGIN-YUBIKEY-' || true)

    # Same argv minus the `-i <stub>` pairs of absent keys, so every flag stays
    # ahead of the input file (Go's flag parsing stops at the first positional).
    args=()
    kept=0
    wanted=()
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -i | --identity)
          id="''${2:-}"
          stub=$(grep -m1 '^AGE-PLUGIN-YUBIKEY-' "$id" 2>/dev/null || true)
          if [ -n "$stub" ] && printf '%s\n' "$connected" | grep -qxF -- "$stub"; then
            args+=("$1" "$id")
            kept=$((kept + 1))
          else
            wanted+=("$(sed -n 's/^#.*Serial: \([0-9]*\).*/\1/p' "$id" 2>/dev/null)")
          fi
          shift
          [ "$#" -gt 0 ] && shift
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done

    if [ "$kept" -eq 0 ]; then
      have=$(printf '%s\n' "$listing" | sed -n 's/^#.*Serial: \([0-9]*\).*/\1/p' | sort -u | paste -sd ' ')
      echo "age: none of this host's identity YubiKeys is connected (connected: ''${have:-none}; identities: ''${wanted[*]}); plug one in, then: systemctl restart agenix-rerun" >&2
      exit 1
    fi

    exec ${pkgs.age}/bin/age "''${args[@]}"
  '';

  # The agenix module installs secrets from NixOS activation scripts, which run
  # in stage-2 BEFORE systemd. age-plugin-yubikey needs pcscd, a socket-activated
  # systemd service, so every boot-time activation fails to decrypt and
  # /run/agenix starts empty (an ordinary `nixos-rebuild switch`, run with pcscd
  # up, is what populates it). agenix-rerun re-executes the exact same snippets
  # once pcscd's socket exists and the YubiKey is enumerated, so consumers that
  # order after it (microVM virtiofs shares, ACME, NetworkManager via modules/vpn)
  # see the secrets on a cold boot — including the first boot after an install.
  snippet = name: lib.attrByPath [name "text"] "" config.system.activationScripts;
  secretPaths = lib.mapAttrsToList (_: s: s.path) config.age.secrets;

  rerunScript = pkgs.writeShellScript "agenix-rerun" ''
    set -u
    missing() {
      for p in ${lib.concatMapStringsSep " " lib.escapeShellArg secretPaths}; do
        [ -e "$p" ] || return 0
      done
      return 1
    }
    if ! missing; then
      echo "[agenix-rerun] all secrets already present; nothing to do"
      exit 0
    fi

    # Give USB a moment: the key may still be enumerating when multi-user
    # starts. No YubiKey at all (e.g. a laptop booted without it) -> fail fast
    # so nothing ordered after us waits on a decrypt that cannot happen.
    n=0
    until ${pkgs.usbutils}/bin/lsusb -d 1050: >/dev/null 2>&1; do
      n=$((n + 1))
      if [ "$n" -ge 5 ]; then
        echo "[agenix-rerun] no YubiKey connected; secrets stay unavailable until one is plugged in and this unit is restarted (systemctl restart agenix-rerun)." >&2
        exit 1
      fi
      sleep 2
    done

    n=0
    while [ "$n" -lt 6 ]; do
      n=$((n + 1))
      echo "[agenix-rerun] attempt $n: re-running the agenix activation with pcscd up..."
      (
        ${snippet "agenixNewGeneration"}
        ${snippet "agenixInstall"}
        ${snippet "agenixChown"}
      ) || true
      if ! missing; then
        echo "[agenix-rerun] secrets populated."
        exit 0
      fi
      sleep 5
    done
    echo "[agenix-rerun] WARNING: secrets still missing after $n attempts (YubiKey present but decryption failed; check pcscd and that this key is a recipient)." >&2
    exit 1
  '';
in {
  imports = [inputs.agenix.nixosModules.default];

  environment.systemPackages = lib.mkIf isAgenix [
    inputs.agenix.packages."x86_64-linux".default
    pkgs.age
    pkgs.age-plugin-yubikey
  ];

  age = lib.mkIf isAgenix {
    # "${./identities}" copies the stubs into their own store path WITH string
    # context, so they are part of the system closure. The old
    # "${toString ./.}/identities/..." had no context: the flake source it pointed
    # into was garbage-collected and agenix found no identities at all.
    identityPaths = map (k: "${./identities}/${k}.key") ["server" "yubi" "dev" "backup"];
    ageBin = "${ageWrapper}";
  };

  # Post-boot secret installation (see the comment above). Only defined on the
  # agenix backend, when this host declares secrets, and when pcscd is enabled
  # (without it the YubiKey plugin cannot work at all, so there is nothing to
  # retry); consumers reference it with wants+after so a host without it is
  # unaffected.
  systemd.services.agenix-rerun = lib.mkIf (isAgenix && config.age.secrets != {} && config.services.pcscd.enable) {
    description = "Re-run agenix secret decryption once pcscd and the YubiKey are available";
    wantedBy = ["multi-user.target"];
    wants = ["pcscd.socket"];
    after = ["pcscd.socket" "systemd-udevd.service"];
    path = [pkgs.coreutils pkgs.util-linux pkgs.gnugrep];
    unitConfig.ConditionPathExists = "/run/agenix.d";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = rerunScript;
    };
  };
}
