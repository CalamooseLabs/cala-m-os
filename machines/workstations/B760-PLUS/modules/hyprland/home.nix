{lib, ...}: let
  gamescopeCommand = "gamescope -f --force-grab-cursor -e -H 2160 -W 3840 --expose-wayland -- steam -tenfoot";
in {
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "HDMI-A-1, 3840x2160@60,  0x0, 1" # 4K TV
        ", preferred, auto, 1, mirror, HDMI-A-1" # Auto Mirror
      ];

      layout = lib.mkForce "dwindle";

      exec-once = [
        "${gamescopeCommand}"
      ];
    };
  };
}
