{
  pkgs,
  modulesPath,
  lib,
  ...
}: {
  imports = [(modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  # Enable SSH in the boot process.
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce ["multi-user.target"];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ./public_keys/id_ed25519_sk.pub
    ./public_keys/backup_id_ed25519_sk.pub
  ];

  networking.hostName = lib.mkForce "cala-m-os-installer";

  programs.bash.enableCompletion = true;

  environment.systemPackages = with pkgs; [
    disko
    git
    neovim
    (pkgs.writeTextFile {
      name = "install-cala-m-os-completion";
      destination = "/share/bash-completion/completions/install-cala-m-os";
      text = ''
        _install_cala_m_os() {
          local cur="''${COMP_WORDS[COMP_CWORD]}"
          if [[ "''${COMP_CWORD}" -eq 1 ]]; then
            local hosts="lanstation devbox ephemeral homelab simple battlestation broadcast openreturn livedata"
            COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
          elif [[ "''${COMP_CWORD}" -eq 2 ]]; then
            local machines="A520M-ITX B760-PLUS B850-MAX FW13-11XXP FW13-12XXP FW16-AMD-AI MS-01 MS-02 TRX50-SAGE ZIMA X-Small Small Medium Large"
            COMPREPLY=($(compgen -W "$machines" -- "$cur"))
          fi
        }
        complete -F _install_cala_m_os install-cala-m-os
      '';
    })
    (pkgs.writeShellScriptBin "install-cala-m-os" ''
      set -eu

      if [ -z "''${1:-}" ]; then
        echo "Usage: $0 <flake> [machine]"
        echo "  <flake>    host configuration to install (e.g. devbox)"
        echo "  [machine]  optional machine to build onto instead of the host's"
        echo "             default (e.g. MS-01). Persisted for future rebuilds."
        exit 1
      fi
      HOST_FLAKE=$1

      # Optional machine override (e.g. build 'devbox' onto an 'MS-01' machine).
      # Exported so disko (which evaluates the flake with --impure) and the
      # install passes all resolve to the overridden machine.
      MACHINE_OVERRIDE=''${2:-}
      export MACHINE_OVERRIDE
      if [ -n "$MACHINE_OVERRIDE" ]; then
        echo "Machine override: building '$HOST_FLAKE' onto machine '$MACHINE_OVERRIDE'"
        echo
      fi

      # Read this host's version mark from the flake (best-effort).
      FLAKE="github:CalamooseLabs/cala-m-os"
      VERSION=$(nix eval --raw --impure "$FLAKE#nixosConfigurations.$HOST_FLAKE.config.calamoose.version" 2>/dev/null || echo "unknown")
      echo "=================================================="
      echo " Installing Cala-M-OS host '$HOST_FLAKE' — version $VERSION"
      echo "=================================================="
      echo

      echo "Step One: Erasing and Formatting Disk"
      disko --mode destroy,format,mount --flake github:CalamooseLabs/cala-m-os#$HOST_FLAKE --yes-wipe-all-disks
      echo "Step One Completed!"
      echo
      echo "Step Two: Installing Minimal NixOS Configuration"
      mkdir /mnt/etc/nixos -p
      git clone https://github.com/calamooselabs/cala-m-os.git /mnt/etc/nixos
      INITIAL_INSTALL_MODE=1 nixos-install --flake /mnt/etc/nixos#$HOST_FLAKE --impure --no-root-password
      echo "Step Two Completed!"
      echo
      echo  "Step Three: Prefetching"
      nix-prefetch-url file:///mnt/etc/nixos/prefetch/displaylink-620.zip
      nixos-enter -- nix-prefetch-url file:///etc/nixos/prefetch/displaylink-620.zip
      echo "Step Three Completed!"
      echo
      # Persist the machine override so future rebuilds on this box keep
      # targeting the overridden machine (the env var is gone after install).
      if [ -n "$MACHINE_OVERRIDE" ]; then
        printf '{\n  %s = "%s";\n}\n' "$HOST_FLAKE" "$MACHINE_OVERRIDE" > /mnt/etc/nixos/machine-override.nix
      fi
      echo "Step Four: Building Cala-M-OS"
      nixos-enter -- env MACHINE_OVERRIDE="$MACHINE_OVERRIDE" nixos-rebuild boot --flake /etc/nixos#$HOST_FLAKE --impure
      echo "Step Four Completed!"
      echo
      echo "Step Five: Setting User Passwords"
      read -rsp "Enter password for hub and root: " PASSWORD
      echo
      read -rsp "Confirm password: " PASSWORD_CONFIRM
      echo
      if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
        echo "Error: Passwords do not match!"
        exit 1
      fi
      printf '%s\n' "hub:$PASSWORD" "root:$PASSWORD" | nixos-enter -- chpasswd
      unset PASSWORD PASSWORD_CONFIRM
      echo "Step Five Completed!"
      echo
      echo "=================================================="
      echo " Cala-M-OS host '$HOST_FLAKE' — version $VERSION installed."
      echo " Please reboot the system."
      echo "=================================================="
      exit
    '')
  ];

  services.pcscd.enable = true;

  isoImage = {
    squashfsCompression = "lz4";
    forceTextMode = true;
  };
}
