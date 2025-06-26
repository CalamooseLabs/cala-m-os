{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "restore-config" ''
      set -eux

      config_path="/etc/nixos"

      sudo nix-store --verify --repair
      nh os switch $config_path

      # Reset network manager
      sudo systemctl restart NetworkManager
    '')
  ];
}
