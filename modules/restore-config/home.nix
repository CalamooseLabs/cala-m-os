{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "restore-config" ''
      set -eux

      config_path="/etc/nixos"

      sudo nix-store --verify --check-contents --repair
      sudo nixos-rebuild switch --flake $config_path
    '')
  ];
}
