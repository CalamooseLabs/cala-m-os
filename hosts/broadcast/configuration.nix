##################################
#                                #
#          Stream Box            #
#       NVIDIA RTX Pro 4000      #
#      Blackmagic Quad HDMI      #
#             OBS                #
#                                #
##################################
{...}: let
  import_users = ["streamer"];
  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";
in {
  calamoose.enableSecrets = false;
  calamoose.version = "1.0.0-beta";

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

  networking.hostName = "broadcast";

  # Pin Hyprland's (Aquamarine) primary renderer to the Intel Arc A310 and include
  # the DisplayLink (evdi) card, so the compositor renders LINEAR buffers the
  # teleprompter can scan out. NVIDIA (RTX PRO 4000) is intentionally excluded — it
  # stays free for OBS NVENC. Stable symlinks come from the intel-gpu module's udev
  # rules. This lives in the session environment (not Hyprland's in-config `env=`)
  # because Aquamarine reads AQ_DRM_DEVICES once at DRM-backend start and Hyprland
  # does not re-apply config `env=` on reload — the session var is present before
  # the compositor execs and survives reloads. Order matters: intel-card is first,
  # so the Arc is the primary renderer.
  environment.sessionVariables = {
    AQ_DRM_DEVICES = "/dev/dri/intel-card:/dev/dri/displaylink-card";

    # The teleprompter is a multi-GPU SECONDARY scanout: Hyprland renders on the Arc,
    # then Aquamarine imports that buffer straight onto the evdi CRTC (per aquamarine
    # PR#25 evdi gets primary={}/rendererRequired=false, so it's a direct drmModeAddFB2,
    # no blit/CPU copy). evdi planes are LINEAR-only, but the discrete Arc A310 (DG2)
    # renders in Tile4/Y-tiled modifiers, so the tiled buffer fails to cross-import to
    # the evdi plane → connector enabled+modeset but the panel stays black ("Buffer
    # failed to import to KMS"). AQ_NO_MODIFIERS forces the AddFB2-WITHOUT-modifiers
    # path so the import succeeds. (devbox works because its AMD iGPU primary emits
    # LINEAR-friendly buffers that cross-import cleanly.) NOTE: AQ_NO_ATOMIC was tried
    # and removed — it is "heavily not recommended", never un-blacks a panel, and the
    # legacy path lacks the per-plane atomic semantics this cross-GPU hand-off needs.
    AQ_NO_MODIFIERS = "1";

    # evdi has no real GPU sync timeline; an explicit fence on the cross-GPU buffer may
    # never signal and present a blank frame. Disable explicit sync on mgpu buffers.
    AQ_MGPU_NO_EXPLICIT = "1";
  };

  # Audio for OBS streaming and monitoring
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };

  services.pulseaudio.enable = false;

  boot.extraModprobeConfig = ''
    options snd_usb_audio vid=0x1235 pid=0x8218 device_setup=1
  '';
}
