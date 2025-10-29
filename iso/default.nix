{
  pkgs,
  modulesPath,
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

  environment.systemPackages = with pkgs; [
    disko
    git
    neovim
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
      echo "Step Three: Building Cala-M-OS"
      nixos-enter -- nixos-rebuild boot --flake /etc/nixos#$HOST_FLAKE
      echo "Step Three Completed!"
      echo
      echo "Cala-M-OS has been sucessfully installed, please reboot the system."
      exit
    '')
  ];

  services.pcscd.enable = true;
}
