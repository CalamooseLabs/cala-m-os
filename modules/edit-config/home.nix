{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "edit-config" ''
      set -eux

      # Run zeditor to edit the NixOS configuration
      direnv exec /etc/nixos bash -c 'zeditor /etc/nixos'
    '')
  ];
}
