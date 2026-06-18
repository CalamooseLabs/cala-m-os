{...}: {
  config,
  lib,
  ...
}: {
  # Broadcast-specific niri config: launch OBS as a maximized kiosk instead of
  # the shared module default (which spawns a browser). mkForce replaces the
  # shared `niri` module's settings entirely rather than merging with them.
  # `obs-kiosk` is provided by hosts/broadcast/configuration.nix and sets the
  # LD_LIBRARY_PATH OBS needs for NVENC before launching.
  programs.niri.settings = lib.mkForce {
    spawn-at-startup = [
      {argv = ["obs-kiosk"];}
    ];

    window-rules = [
      {
        matches = [{app-id = "com.obsproject.Studio";}];
        open-maximized = true;
      }
    ];

    binds = with config.lib.niri.actions; {
      "Mod+T".action = spawn "ghostty";
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+F".action = maximize-column;
      "Mod+M".action = maximize-window-to-edges;
    };
  };
}
