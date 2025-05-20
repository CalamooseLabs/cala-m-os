{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "rebuild-config" ''
      set -eux

      lazygit -p /etc/nixos
      # Run zeditor to edit the NixOS configuration
      sudo nixos-rebuild switch --flake /etc/nixos
    '')
  ];
}
