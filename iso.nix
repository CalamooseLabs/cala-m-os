{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    disko
    git
    neovim
    (pkgs.writeShellScriptBin "install-cala-m-os" ''
      set -eux

      if [ -z "$1" ]; then
        echo "Usage: $0 <flake>"
        exit 1
      fi
      HOST_FLAKE=$1

      echo "Step One: Generating Configuration"
      nixos-generate-config --no-filesystem
      echo "Step One Completed!"
      echo
      echo "Step Two: Erasing and Formatting Disk"
      disko --mode destroy,format,mount --flake github:CalamooseLabs/cala-m-os#$HOST_FLAKE
      echo "Step Two Completed!"
      echo
      echo "Step Three: Installing Minimal NixOS Configuration"
      nixos-install
      echo "Step Three Completed!"
      echo
      echo "Step Four: Cloning Cala-M-OS"
      git clone https://github.com/calamooselabs/cala-m-os /mnt/etc/nixos/
      echo "Step Four Completed!"
      echo
      echo "Step Five: Building Cala-M-OS"
      nixos-enter -- nixos-rebuild boot --flake /etc/nixos#$HOST_FLAKE --option allow-unfree true --experimental-features 'nix-command flakes'
      echo "Step Five Completed!"
      echo
      echo "Step Six: Adding GPG Key to Default User"
      echo "Step Six Completed!"
      echo
      echo "Step Seven: Adding SSH Key to Default User"
      echo "Step Seven Completed!"
      echo
      echo
      echo "Cala-M-OS has been sucessfully installed, please reboot the system."
      exit
    '') # TODO: Add prefetch to the rebuild process
  ];

  services.pcscd.enable = true;
}
