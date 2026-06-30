{...}: {...}: {
  wayland.windowManager.hyprland.settings = {
    # Autostart the OBS kiosk (the niri module's spawn-at-startup equivalent).
    exec-once = ["obs-kiosk"];

    # NOTE: the primary-renderer pinning (AQ_DRM_DEVICES → AMD GPU + the
    # DisplayLink/evdi card, nvidia excluded for OBS NVENC) now lives in
    # hosts/broadcast/configuration.nix as environment.sessionVariables. Aquamarine
    # reads AQ_DRM_DEVICES once, when the DRM backend starts; an in-config `env=`
    # here is honored on first launch but is NOT re-applied on a Hyprland config
    # reload (the first-launch guard), so a reload could silently leave the
    # renderer unpinned. Exporting it in the session env (present before the
    # compositor execs) makes the pinning reload-immune.

    # Force fullscreen surfaces through composition instead of direct scanout.
    # OBS is PRIME-offloaded to the RTX PRO 4000, so its window buffers are
    # nvidia block-linear dmabufs. A composited window is fine (the AMD GPU samples
    # it, then copies to a LINEAR buffer for the evdi prompter), but an OBS
    # fullscreen projector is eligible for direct scanout — Hyprland would try to
    # scan the nvidia-tiled buffer straight onto the evdi plane, which is
    # LINEAR-only, so the modifier intersection is empty and the prompter goes
    # black. Disabling direct scanout keeps the projector on the working
    # composition→LINEAR path.
    render.direct_scanout = 0;
  };
}
