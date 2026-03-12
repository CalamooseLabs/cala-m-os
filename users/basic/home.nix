{...}: {...}: {
  services.easyeffects = {
    preset = "FW13";
  };

  wayland.windowManager.hyprland = {
    settings = {
      # Startup Apps
      exec-once = [
        "ashell"
        "nwg-dock-hyprland -nolauncher"
      ];
    };
  };
}
