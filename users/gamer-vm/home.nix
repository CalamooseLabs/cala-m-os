{...}: {pkgs, ...}: {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  wayland.windowManager.hyprland = {
    settings = {
      exec-once = [
        "gamescope -f --force-grab-cursor --mangoapp --expose-wayland -- steam -tenfoot"
      ];
    };
  };
}
