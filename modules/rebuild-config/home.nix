{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "rebuild-config" ''
      set -eux

      config_path="/etc/nixos"

      if [ -n "$(git -C $config_path status --porcelain)" ]; then
        lazygit -p $config_path
      fi

      nh os switch $config_path
    '')
  ];
}
