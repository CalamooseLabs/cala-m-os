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
  calamoose.version = "1.1.1-beta";
  calamoose.style = "thecompany"; # The Company, Inc. brand theme

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
      # THE fix for gen2 "Switch root target contains no usable init" (found Jul 21
      # 2026 — it was the secrets, not the kernel). With systemd stage-1, NixOS runs
      # this system's `activate` INSIDE the initrd (initrd-nixos-activation → chroot
      # /sysroot .../prepare-root), where there is NO network. With the default
      # failClosed=true the Proton preflight/fetch does `exit 1`, which kills
      # `activate` BEFORE its `etc` snippet creates /sysroot/{etc/os-release,sbin/init}
      # — so systemd's switch-root usable-init check fails and the box never boots
      # past stage-1. gen1 (minimal install) has no proton snippet, which is the only
      # reason it boots. Non-fatal lets `activate` finish so /sysroot is populated and
      # switch-root succeeds; secrets are best-effort at boot and refetched once the
      # network is up (a later activation, or `sudo proton-secrets login` + rebuild).
      services.proton-secrets.failClosed = false;
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

  # Boot visibility + recoverability. A stage-1 failure on this box once showed
  # only a bare "no usable init" — the console was silenced (loglevel=0, from
  # core's consoleLogLevel = 0) and the hidden boot menu (core timeout 0) made
  # picking a working generation needlessly hard on a machine that's rarely at
  # hand. Keep boot visible here; a stream box boots off-air anyway.
  boot.plymouth.enable = false; # no splash painting over the console
  boot.consoleLogLevel = lib.mkForce 6; # emits loglevel=6, last-wins over core's 3/0
  # Stage-1 is systemd-based (boot.initrd.systemd), so core's quiet/
  # rd.systemd.show_status=false would still hide unit status — and its
  # boot.shell_on_fail is a scripted-initrd param that is inert here. mkAfter
  # wins (later rd.systemd.show_status overrides the earlier one), and
  # emergencyAccess is the systemd-initrd equivalent of shell_on_fail: on a
  # stage-1 failure drop to a root emergency shell (physical-access box).
  boot.kernelParams = lib.mkAfter ["rd.systemd.show_status=true" "systemd.show_status=true"];
  boot.initrd.systemd.emergencyAccess = true;
  boot.loader.timeout = 5; # core defaults 0 (hidden menu)
  boot.loader.systemd-boot.configurationLimit = 10; # bounded, keeps fallback gens

  # With amdgpu no longer force-loaded in the initrd (see machines/modules/
  # amd-gpu), the card is probed by udev in stage-2 — so greetd can win the race
  # against /dev/dri/amd-card appearing, Hyprland then finds no usable
  # AQ_DRM_DEVICES primary and exits, and greetd (Restart=on-success upstream)
  # would die once and leave a permanently black seat. Two-layer guard:
  # wait briefly for the card before launching, and always restart the seat so
  # any lost race (or Hyprland crash) is a 2s blink instead of a dead console.
  services.greetd.settings.default_session.command = lib.mkForce "sh -c 'for _ in $(seq 100); do [ -e /dev/dri/amd-card ] && break; sleep 0.1; done; start-hyprland &> /dev/null'";
  systemd.services.greetd.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = 2;
  };
}
