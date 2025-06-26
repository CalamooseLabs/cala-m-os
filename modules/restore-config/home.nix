{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "restore-config" ''
      set -eux

      config_path="/etc/nixos"

      sudo nix-store --verify --repair
      sudo nh os switch

      # Reset network manager
      sudo systemctl restart NetworkManager
    '')
  ];
}
