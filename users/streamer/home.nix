{...}: {...}: {
  wayland.windowManager.hyprland.settings = {
    # Autostart the OBS kiosk (the niri module's spawn-at-startup equivalent).
    exec-once = ["obs-kiosk"];

    # Pin the compositor's primary renderer to the Intel Arc A310 and include the
    # DisplayLink (evdi) card, so Hyprland renders LINEAR buffers the teleprompter
    # can scan out. nvidia is intentionally excluded here — it stays free for OBS
    # NVENC. Stable symlinks come from the intel-gpu module's udev rules.
    env = ["AQ_DRM_DEVICES,/dev/dri/intel-card:/dev/dri/displaylink-card"];

    # Force fullscreen surfaces through composition instead of direct scanout.
    # OBS is PRIME-offloaded to the RTX PRO 4000, so its window buffers are
    # nvidia block-linear dmabufs. A composited window is fine (Arc samples it,
    # then copies to a LINEAR buffer for the evdi prompter), but an OBS fullscreen
    # projector is eligible for direct scanout — Hyprland would try to scan the
    # nvidia-tiled buffer straight onto the evdi plane, which is LINEAR-only, so
    # the modifier intersection is empty and the prompter goes black. Disabling
    # direct scanout keeps the projector on the working composition→LINEAR path.
    render.direct_scanout = 0;
  };
}
