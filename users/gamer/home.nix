{...}: {pkgs, ...}: {
  # wayland.windowManager.hyprland = {
  #   settings = {
  #     exec-once = [
  #       "steam"
  #     ];

  #     bind = ["$mod, S, exec, steam"];
  #   };
  # };
  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];
}
