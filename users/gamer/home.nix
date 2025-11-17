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
  ];

  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "HDMI-A-1, 3840x2160@60,  0x0, 1" # 4K TV
      ];

      exec-once = [
        "${gamescopeCommand}"
      ];
    };
  };
}
