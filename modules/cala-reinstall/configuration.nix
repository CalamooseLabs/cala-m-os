# cala-reinstall — turn this running host back into the Cala-M-OS installer with
# no USB stick or mounted ISO (remote boxes, cloud VMs). It kexecs into the
# RAM-only installer (flake output `installer-kexec`, iso/kexec.nix), carrying
# this host's GitHub token or Proton PAT, SSH keys and static network along.
# Nothing on disk changes until the install is run from the installer; a hard
# reset before then boots this system again.
#
# Imported for every physical host by hosts/_core/non-vm.nix.
#
#   sudo cala-reinstall [--dry-run] [--yes] [--flake REF | --image DIR] [--variant full|vm] …
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.cala-reinstall;

  cala-reinstall = pkgs.writeShellApplication {
    name = "cala-reinstall";
    runtimeInputs = with pkgs; [kexec-tools cpio jq iproute2 coreutils findutils gnugrep gnused systemd];
    text =
      ''
        CALA_REINSTALL_FLAKE="''${CALA_REINSTALL_FLAKE:-${cfg.flake}}"
        CALA_REINSTALL_VARIANT="''${CALA_REINSTALL_VARIANT:-${cfg.variant}}"
        CALA_REINSTALL_HOSTKEYS=${lib.escapeShellArg (toString (map (k: k.path) config.services.openssh.hostKeys))}
      ''
      + builtins.readFile ./cala-reinstall.sh;
  };
in {
  options.programs.cala-reinstall = {
    flake = lib.mkOption {
      type = lib.types.str;
      default = "github:CalamooseLabs/cala-m-os";
      description = "Flake whose `installer-kexec` / `installer-kexec-vm` output cala-reinstall boots into.";
    };

    variant = lib.mkOption {
      type = lib.types.enum ["auto" "full" "vm"];
      default = "auto";
      description = ''
        Which installer image to load: `full` carries linux-firmware (bare-metal
        NICs may need a blob to come back with network), `vm` leaves it out and
        is about half the size — what fits a 4 GB cloud VM. `auto` (default)
        picks `vm` when systemd-detect-virt reports a virtual machine. The image
        is built for this host's own architecture via the flake's
        `packages.<system>`.
      '';
    };
  };

  config.environment.systemPackages = [cala-reinstall];
}
