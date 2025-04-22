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
    # Do the following:
    # Grab latest from master on github
    # run the prefetch
    # run the disko-install
    # nixos-enter
    # set repo to /etc/nixos
    # chown wheel
    # 770 chmod
    # prefetch
    # nixos-rebuild
    # reboot
    (pkgs.writeShellScriptBin "install-cala-m-os" ''
      set -eux
      rm /etc/nixos/*
      git clone https://github.com/calamooselabs/cala-m-os /etc/nixos/
      exec ${pkgs.disko}/bin/disko-install --write-efi-boot-entries --flake "/etc/nixos/.#calamooselabs" --disk main "/dev/nvme0n1"
    '')
  ];

  services.pcscd.enable = true;
}
