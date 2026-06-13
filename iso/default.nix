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
            local hosts="lanstation devbox ephemeral lab simple battlestation studio openreturn livedata"
            COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
          fi
        }
        complete -F _install_cala_m_os install-cala-m-os
      '';
    })
    (pkgs.writeShellScriptBin "install-cala-m-os" ''
      set -eu

      if [ -z "$1" ]; then
        echo "Usage: $0 <flake>"
        exit 1
      fi
      HOST_FLAKE=$1

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
      echo "Step Four: Building Cala-M-OS"
      nixos-enter -- nixos-rebuild boot --flake /etc/nixos#$HOST_FLAKE
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
      echo "Cala-M-OS has been successfully installed, please reboot the system."
      exit
    '')
  ];

  services.pcscd.enable = true;

  isoImage = {
    squashfsCompression = "lz4";
    forceTextMode = true;
  };
}
