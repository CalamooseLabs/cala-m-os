{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "start-vms" ''
      sudo systemctl start microvm@lanstation-2.service
    '')

    (pkgs.writeShellScriptBin "rebuild-config" ''
      set -eux

      config_path="/etc/nixos"

      pushd "$config_path" > /dev/null

      git pull

      nh os switch $config_path -H lanstation

      popd > /dev/null
    '')
  ];
}
