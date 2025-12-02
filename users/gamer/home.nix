{...}: {pkgs, ...}: let
  gamescopeCommand = "gamescope -f --force-grab-cursor -e -H 2160 -W 3840 --expose-wayland -- steam -tenfoot";
in {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
    (pkgs.writeShellScriptBin "start-gaming" ''
      set -eux

      bash -c '${gamescopeCommand}'
    '')
    (pkgs.writeShellScriptBin "start-vms" ''
      sudo systemctl start microvm@lanstation-2.service
      sudo systemctl start microvm@lanstation-3.service
      sudo systemctl start microvm@lanstation-4.service
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

  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "HDMI-A-1, 3840x2160@60,  0x0, 1" # 4K TV
        ", preferred, auto, 1, mirror, HDMI-A-1" # Auto Mirror
      ];

      exec-once = [
        "${gamescopeCommand}"
      ];
    };
  };
}
