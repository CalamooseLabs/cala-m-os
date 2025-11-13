{...}: {pkgs, ...}: {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "HDMI-1, 3840x2160@120,  0x0, 1" # 4K TV
      ];

      exec-once = [
        "gamescope -f --force-grab-cursor --mangoapp -e -H 2160 -W 3840 --expose-wayland -- steam -tenfoot"
      ];
    };
  };
}
