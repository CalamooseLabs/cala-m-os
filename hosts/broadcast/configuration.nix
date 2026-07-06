##################################
#                                #
#          Stream Box            #
#       NVIDIA RTX Pro 4000      #
#      Blackmagic Quad HDMI      #
#             OBS                #
#                                #
##################################
{
  lib,
  initialInstallMode,
  ...
}: let
  import_users = ["streamer"];
  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";
in {
  # Online (Proton Pass) secrets — fetched at activation. Consumed here:
  #   users/_core/secrets/default.nix -> admin_password (hub hashedPasswordFile)
  #   modules/multichat/secrets       -> youtube-api-key (multichat apiKeyFile)
  calamoose.enableSecrets = "online";
  calamoose.version = "1.0.1-beta";

  # Re-mint a Proton session from the installer-seeded PAT (same pattern as `ai`).
  # The fs-provider session is bound to the machine-id, so the session the ISO
  # installer copies onto the target won't match this box's freshly generated
  # machine-id — the activation preflight then reports "no usable Proton Pass
  # session" on first boot. A PAT is machine-id-independent, so this re-establishes
  # a valid session; the installer seeds it to /var/lib/proton-pass-cli/pat when you
  # supply a PAT at the prompt (or pre-provision one with `flash-iso --with-pat`).
  # Once minted, the session persists here (persistent root), so later boots reuse
  # it and never touch the PAT again. (Without a seeded PAT you can still bootstrap
  # by hand on the running host: `sudo proton-secrets login`.)
  #
  # Applied as a conditional import — NOT
  # `services.proton-secrets.patFile = mkIf (!initialInstallMode) …` — because the
  # option-existence check fires on the definition path regardless of the mkIf
  # condition, so during the minimal-install pass (where the proton-secrets module
  # is absent) mkIf would still error "option does not exist". lib.optional drops
  # the definition entirely there.
  imports =
    [
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ]
    ++ lib.optional (!initialInstallMode) {
      services.proton-secrets.patFile = "/var/lib/proton-pass-cli/pat";
    };

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
