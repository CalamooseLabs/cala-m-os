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
      rm /etc/nixos/*
      git clone https://github.com/calamooselabs/cala-m-os /etc/nixos/
      disko --mode destroy,format,mount --flake /etc/nixos/.#devbox
      nixos-install --flake /etc/nixos/.#devbox
      nixos-enter
      git clone https://github.com/calamooselabs/cala-m-os /etc/nixos/
      nixos-rebuild switch --flake /etc/nixos/.#devbox
      exit
    '')
  ];

  services.pcscd.enable = true;
}
