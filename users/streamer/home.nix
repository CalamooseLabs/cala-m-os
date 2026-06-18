{...}: {lib, ...}: {
  # Broadcast-specific niri config: launch OBS as a maximized kiosk instead of
  # the shared module default (which spawns a browser).
  xdg.configFile."niri/config.kdl".source = lib.mkForce ./niri.kdl;
}
