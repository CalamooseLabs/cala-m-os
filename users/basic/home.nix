{...}: {...}: {
  services.easyeffects = {
    preset = "FW13";
  };

  wayland.windowManager.hyprland = {
    settings = {
      # decoration = {
      #   shadow_offset = "0 5";
      #   "col.shadow" = "rgba(00000099)";
      # };

      # Startup Apps
      exec-once = [
        "ashell"
        "nwg-dock-hyprland"
      ];
    };
  };
}
