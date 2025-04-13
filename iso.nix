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
    age-plugin-yubikey
    (pkgs.writeShellScriptBin "install-cala-m-os" ''
      set -eux
      rm /etc/nixos/*
      git clone https://github.com/calamooselabs/cala-m-os /etc/nixos/
      exec ${pkgs.disko}/bin/disko-install --write-efi-boot-entries --flake "/etc/nixos/.#calamooselabs" --disk main "/dev/nvme0n1"
    '')
  ];

  services.pcscd.enable = true;
}
