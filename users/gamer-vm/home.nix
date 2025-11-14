{...}: {pkgs, ...}: {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "HDMI-A-1, 3840x2160@60,  0x0, 1" # 4K TV
        "DP-5, 3840x2160@60,  0x0, 1" # 4K TV
      ];

      exec-once = [
        "gamescope -f --force-grab-cursor -e -H 2160 -W 3840 --expose-wayland -- steam -tenfoot"
      ];
    };
  };
}
