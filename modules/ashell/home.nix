{...}: {
  programs.ashell = {
    enable = true;
    settings = {
      app_launcher_cmd = "rofi";
      appearance = {
        scale_factor = 1.5;
      };
      clock = {
        format = "%a %d %b  -  %r";
      };
      modules = {
        left = ["Clock"];
        center = ["WindowTitle"];
        right = ["Settings"];
      };

      settings = {
        battery_format = "IconAndPercentage";
        lock_cmd = "hyprlock &";
        indicators = [
          "Battery"
          "Bluetooth"
          "Network"
          "Audio"
        ];
      };
    };
  };
}
