{...}: {...}: {
  wayland.windowManager.hyprland.settings = {
    # Autostart the OBS kiosk (the niri module's spawn-at-startup equivalent).
    exec-once = ["obs-kiosk"];

    # Pin the compositor's primary renderer to the Intel Arc A310 and include the
    # DisplayLink (evdi) card, so Hyprland renders LINEAR buffers the teleprompter
    # can scan out. nvidia is intentionally excluded here — it stays free for OBS
    # NVENC. Stable symlinks come from the intel-gpu module's udev rules.
    env = ["AQ_DRM_DEVICES,/dev/dri/intel-card:/dev/dri/displaylink-card"];
  };
}
