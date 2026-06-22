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

    # evdi/DisplayLink does not support non-blocking ATOMIC page-flips. Aquamarine's
    # atomic commit to the prompter's CRTC fails once at modeset with EBUSY ("atomic
    # drm request: failed to commit: Device or resource busy", flags ATOMIC_NONBLOCK
    # PAGE_FLIP_EVENT); the non-blocking flip never returns a completion event, so the
    # output stalls and presents nothing — permanently black even though it is enabled
    # and correctly modeset with LINEAR buffers. Force the legacy DRM API, which evdi
    # supports. Global (also moves the Arc-driven JetKVM to legacy KMS, which is fine).
    AQ_NO_ATOMIC = "1";
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
