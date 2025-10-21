{...}: {pkgs, ...}: {
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  wayland.windowManager.hyprland = {
    settings = {
      # exec-once = [
      #   "gamescope -- steam -bigpicture"
      # ];

      bind = ["$mod, S, exec, steam"];
    };
  };
}
