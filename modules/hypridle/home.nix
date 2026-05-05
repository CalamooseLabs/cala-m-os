{...}: {
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof hyprlock || hyprlock";
      };

      listener = [
        {
          timeout = 3600; # 1 Hour
          on-timeout = "hyprctl dispatch dpms off && (pidof hyprlock || hyprlock)";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
