{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  isAgenix = config.calamoose._secretsBackend == "agenix";

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
    identityPaths = [
      "${toString ./.}/identities/server.key"
      "${toString ./.}/identities/yubi.key"
      "${toString ./.}/identities/dev.key"
      "${toString ./.}/identities/backup.key"
    ];
    ageBin = "PATH=$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey]} ${pkgs.age}/bin/age";
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
