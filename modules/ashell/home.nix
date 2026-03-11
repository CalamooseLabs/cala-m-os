{...}: {
  programs.ashell = {
    enable = true;
    settings = {
      app_launcher_cmd = "rofi";
      appearance = {
        scale_factor = 1.5;
      };
      clock = {
        format = "%a %d %b %r";
      };
      modules = {
        left = ["Workspaces"];
        center = ["WindowTitle"];
        right = ["SystemInfo" "Clock" "Settings"]; # Settings includes battery
      };

      # Configure battery display format
      settings = {
        battery_format = "IconAndPercentage"; # Shows both icon and percentage
      };
    };
  };
}
