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

  # Pin Hyprland's (Aquamarine) primary renderer to the AMD GPU and include the
  # DisplayLink (evdi) card. WHY THIS WORKS ON AMD BUT NOT THE OLD ARC: Aquamarine
  # special-cases evdi as a NON-multigpu output (primary={}, rendererRequired=false,
  # PR#25) and hands it the primary renderer's buffer directly — it never does the
  # LINEAR blit it reserves for multigpu outputs. So the primary GPU must NATIVELY
  # produce evdi-importable (LINEAR-friendly) scanout buffers. AMD does (this is the
  # exact path that works on devbox's AMD iGPU); a discrete Intel Arc / NVIDIA hands
  # evdi a tiled buffer its LINEAR-only plane rejects → black, and NO AQ_* env var
  # changes that (AQ_NO_MODIFIERS / AQ_MGPU_NO_EXPLICIT only touch the multigpu path
  # evdi never enters — they were removed as no-op confounders). NVIDIA (RTX PRO
  # 4000) is intentionally excluded from the device list so it stays free for OBS
  # NVENC, which uses PRIME render-offload independent of the compositor's DRM set.
  # Stable symlinks: amd-card from the amd-gpu module, displaylink-card from the
  # teleprompter module. This lives in the session env (not Hyprland's in-config
  # `env=`) because Aquamarine reads AQ_DRM_DEVICES once at DRM-backend start and
  # does not re-apply config `env=` on reload. Order matters: amd-card first = primary.
  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/amd-card:/dev/dri/displaylink-card";

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
