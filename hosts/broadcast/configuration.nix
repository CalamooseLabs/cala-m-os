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
  cala-m-os,
  ...
}: let
  import_users = ["streamer"];
  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";
in {
  # Online (Proton Pass) secrets: fetched by a boot-time unit and at every
  # switch, and (cache.enable below) restored from a sealed last-known-good
  # copy before any service starts. modules/secrets has the whole boot story.
  # Consumed here:
  #   users/_core/secrets/default.nix -> admin_password (hub hashedPasswordFile)
  #   modules/multichat/secrets       -> youtube-api-key, twitch-client-secret,
  #                                      twitch-refresh-* (multichat)
  #   modules/chatcards/secrets       -> cardsight-api-key, pricecharting-token
  #                                      (chat-cards)
  #   this file (below)               -> stream-key-* (OBS stream keys)
  calamoose.enableSecrets = "online";
  calamoose.version = "1.5.0";
  calamoose.style = "thecompany"; # The Company, Inc. brand theme

  # The installer-seeded PAT (same pattern as `ai`): the file the fetch logs in
  # from whenever this box has no usable Proton session. The installer seeds it
  # to /var/lib/proton-pass-cli/pat when you supply a PAT at the prompt (or
  # pre-provision one with `flash-iso --with-pat`). A session made from it
  # persists here (persistent root) and is reused, but not for ever: Proton can
  # drop it, and a power cut shortly after a login can leave its files unusable.
  # The fetch then logs in from this file again, and having it is also what
  # lets the fetch throw such a session away by itself; with no PAT that repair
  # is by hand (`sudo proton-secrets repair --force`, then `sudo proton-secrets
  # login`). The session is NOT tied to the machine — it is bound to neither the
  # machine-id nor the hostname — so nothing needs redoing when those change.
  # A PAT expires (one year at most) and can be deleted from the account. When
  # Proton rejects it the fetch unit stops with exit 78 and stays failed —
  # `systemctl status proton-secrets-fetch`, and `sudo proton-secrets doctor`
  # says pat-invalid — until this file holds a valid one and `sudo
  # proton-secrets repair`, then `sudo proton-secrets refresh`, have been run.
  # Give this box a long-lived PAT of its own, not whatever the install media
  # carried (wiki: ISO-Installer).
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
    ++ lib.optional (!initialInstallMode) ({config, ...}: {
      services.proton-secrets.patFile = "/var/lib/proton-pass-cli/pat";

      # Secrets are best-effort on this box: a switch that could not read every
      # secret installs what it did read, keeps the previous value of the rest,
      # warns and goes through (the default would change nothing and fail the
      # switch), so a Proton hiccup or one bad vault field never blocks a
      # deploy. The boot-time unit behaves this way whatever is set here, and
      # reports through its exit code instead. This is not what keeps the boot
      # safe: the fetch is skipped inside the initrd whatever it is set to (the
      # gen2 "no usable init" hang, see machines/workstations/TRX50-SAGE).
      services.proton-secrets.failClosed = false;

      # Keep a sealed last-known-good copy of every secret on disk and restore
      # it before any service starts (proton-secrets-restore.service). What it
      # buys an always-on box: multichat, chat-cards and the stream keys are
      # there at boot with the values last read from Proton, without waiting
      # for it; an expired PAT, a broken session or a Proton or internet outage
      # does not take the stream box down at its next power cycle; and a secret
      # rotated in Proton Pass still arrives with the next successful fetch,
      # which also restarts its consumers.
      # What it costs, honestly: the secrets now exist at rest. They are
      # encrypted by systemd-creds with the host key,
      # /var/lib/systemd/credential.secret — which lives on the same
      # unencrypted disk as the cache, and as the PAT. So this protects a copy
      # of /var/lib/proton-secrets-cache that leaves the box on its own (a
      # backup, a stray rsync); it does NOT protect a stolen disk — but a
      # stolen disk gives the vault away regardless: the PAT on it opens it.
      # A secret revoked in Proton also stays usable from the cache until the
      # next successful fetch replaces it.
      services.proton-secrets.cache.enable = true;

      # OBS + Bitfocus Companion baselines are owned by this HOST (broadcast =
      # streaming role + brand identity), not the TRX50-SAGE machine (hardware).
      # Wired inside the non-install branch on purpose: the bitfocus-companion
      # module and home-manager only exist in the full config, not the minimal
      # INITIAL_INSTALL_MODE pass — the same reason the machine files (evaluated
      # only in full mode) could set these unguarded.
      #
      # seedDb auto-wires once hosts/broadcast/companion/db.sqlite is committed;
      # push it back with `sudo companion-restore`, capture live changes with
      # `sudo companion-snapshot`. The committed db carries a BLANK OBS-WebSocket
      # password on purpose: OBS runs its websocket with auth DISABLED (port 4455
      # is firewalled to localhost, single-user box — see ./home.nix), so Companion
      # connects over loopback with no password and there is no secret to manage.
      services.bitfocus-companion.seedDb = let
        p = ./companion/db.sqlite;
      in
        if builtins.pathExists p
        then p
        else null;
      services.bitfocus-companion.repoPath = "/etc/nixos/hosts/broadcast/companion";

      # Companion 4.x ships ZERO connection modules — normally each is downloaded
      # from the Bitfocus module store into /var/lib/bitfocus-companion/modules/,
      # which a reinstall wipes. The seeded db pins these EXACT versions
      # (moduleVersionId per connection) and Companion never auto-installs, so
      # without pre-seeding every connection came up "Unknown module" after each
      # reinstall until deleted and re-added by hand. Keep this list in lockstep
      # with the committed db: whenever a snapshot/export changes a connection's
      # moduleVersionId, add the matching entry here (see connectionModules option
      # docs in modules/bitfocus-companion for how to get url + hash from the
      # store API). The elgato-stream-deck surface is "builtin" — ships in the
      # package, nothing to seed.
      services.bitfocus-companion.connectionModules = {
        "obs-studio-3.15.3" = {
          url = "https://developer-module-builds.s4.bitfocus.io/connection/obs-studio/v3.15.3-64a9f074fc8f6ee4eefd86e6e7e9396e76b44050/obs-studio-v3.15.3.tgz";
          hash = "sha256-pM6YBUu1xMWXm2rvoVFGl1c2m6H46nwRD/mUGpWRdpA=";
        };
        "generic-http-3.1.1" = {
          url = "https://developer-module-builds.s4.bitfocus.io/connection/generic-http/v3.1.1-aa2f436c546b4aa1f8081938c9db7528b246d43e/generic-http-v3.1.1.tgz";
          hash = "sha256-oiHRs+SX1FHHoj+yser6+YtjmXX/TwJfat/2CJBbUrM=";
        };
        "twitch-api-4.1.1" = {
          url = "https://developer-module-builds.s4.bitfocus.io/connection/twitch-api/v4.1.1-0eb88139b7c913f618271c8e3af89b555b1318f2/twitch-api-v4.1.1.tgz";
          hash = "sha256-gKidGWtGU7gNebFeY23a2QRDfJJIGReZXlQGhPaFw8Q=";
        };
      };

      # Host-level home-manager entry point (merges with the machine's home.nix
      # via the list-typed sharedModules option) — carries the OBS baseline seed,
      # $HOME media assets, and the seeded (auth-disabled) OBS-websocket config.
      # See ./home.nix.
      home-manager.sharedModules = [./home.nix];

      # OBS stream keys for The Company, Inc. — one Proton Pass item ("Stream
      # Keys", vault Cala-M-OS) with a field per destination. Owned by the
      # session user: obs-stream-keys runs as hub from obs-kiosk, right before
      # each OBS launch, and writes them into the live OBS config (see
      # calamoose.obs.streamKeys in modules/obs-studio). The committed baseline
      # carries NO keys — service.json's key is blank and obs-config-snapshot
      # blanks it again.
      # No restartUnits on these three, on purpose: OBS reads keys only at
      # launch, and a secrets refresh must never restart OBS — it may be live.
      # Rotating a key is therefore two steps:
      #   1. update the field in Proton Pass, then get the file refreshed: `sudo
      #      proton-secrets refresh` (fetches now and prints the result per
      #      secret), a rebuild switch, or a reboot;
      #   2. quit OBS and relaunch it via obs-kiosk / the bar pill, off air.
      # A reboot alone is NOT a reliable way to do both: the OBS that autostarts
      # with the session is keyed from the files as they are at that moment —
      # normally the cached, old key — and the fetch replaces them only once the
      # network is up. Quit + relaunch OBS after it has.
      # A missing, renamed or blank field costs only that one key: the fetch
      # keeps its previous (or cached) value, installs the other secrets and
      # reports the secret by name — in `sudo proton-secrets doctor` (the
      # per-secret lines of the last fetch, each with its reason), in
      # /run/proton-secrets.status, and in `systemctl status
      # proton-secrets-fetch`, which is not active until every secret was read.
      # A switch still exits 0 (failClosed above) with a warning. To check a
      # field without printing it — the count should be well above 1; 0 or 1
      # means it came back empty:
      #   sudo proton-secrets resolve --vault-name Cala-M-OS --item-title 'Stream Keys' --field 'YouTube Vertical' | wc -c
      calamoose.secrets = let
        streamKey = field: {
          vaultName = "Cala-M-OS";
          itemTitle = "Stream Keys";
          inherit field;
          owner = cala-m-os.globals.defaultUser;
        };
      in {
        "stream-key-twitch" = streamKey "Twitch";
        "stream-key-youtube" = streamKey "YouTube";
        "stream-key-youtube-vertical" = streamKey "YouTube Vertical";
      };

      # Where each key goes. Existing outputs keep their name/settings and just
      # get the key; one is created only when none qualifies.
      #   Twitch           main output (service.json, Twitch + Enhanced
      #                    Broadcasting, which also carries the vertical canvas)
      #   YouTube          every youtube.com Aitum Multistream output of this
      #                    profile (a primary + backup pair shares the key)
      #   YouTube Vertical the Aitum Vertical output NAMED "YouTube Vertical"
      #                    (a youtube.com output already holding this exact
      #                    key is renamed to that once). That plugin's config
      #                    is GLOBAL (it also shows under TheCalamoose), so
      #                    another channel's YouTube output there is left alone.
      calamoose.obs.streamKeys = let
        youtube = "rtmps://a.rtmps.youtube.com:443/live2";
      in {
        twitch = {
          target = "service";
          profile = "The_Company_Inc";
          match = "twitch";
          keyFile = config.calamoose.secrets."stream-key-twitch".path;
        };
        youtube = {
          target = "multistream";
          profile = "The_Company_Inc";
          match = "youtube.com";
          create = {
            name = "YouTube";
            server = youtube;
          };
          keyFile = config.calamoose.secrets."stream-key-youtube".path;
        };
        youtube-vertical = {
          target = "vertical";
          match = "youtube.com";
          create = {
            name = "YouTube Vertical";
            server = youtube;
          };
          keyFile = config.calamoose.secrets."stream-key-youtube-vertical".path;
        };
      };
    });

  networking.hostName = "broadcast";

  # Physical power button: don't let logind hard-poweroff a box that's likely
  # mid-stream. Hyprland binds XF86PowerOff to obs-safe-poweroff instead (see
  # ./home.nix), which lets OBS exit cleanly — saving config and clearing its
  # crash sentinel — before systemctl poweroff, so the next launch skips the
  # "did not shut down properly / Safe Mode?" dialog. A ≥5s hold stays a forced
  # poweroff for when the session itself is wedged (Hyprland dead = nothing
  # listening for the short press).
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };

  # Always on. This box is also the mailroom server (modules/mailroom): a phone
  # may publish to it at any hour and its services have to be there when it
  # does, so the machine must never put itself to sleep. Nothing in the
  # streamer profile asks for sleep today (no hypridle), but that is an
  # absence, not a guarantee: one `systemctl suspend`, a desktop applet or a
  # future module would take the ingest down until someone walked to the box.
  # sleep.conf makes every sleep verb fail instead. Coming back by itself
  # after a power cut is the other half and lives outside this repo: the
  # firmware's "restore on AC power loss" must be set to power on (after that,
  # greetd auto-logs in and everything below starts unattended).
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # Core's nix-gc is daily at midnight with Persistent=true and a three-day
  # horizon, which is wrong for this box two ways. A missed midnight run fires
  # at the next boot, i.e. while the box is being brought up for a stream. And
  # a box that is rebuilt once in a while loses every older generation after
  # three days, while their boot-menu entries stay (configurationLimit below)
  # and point at inits that are gone, so the known-good generation this host
  # keeps the menu visible for is not there when it is needed.
  # Weekly, off air, a month of generations, never caught up at boot.
  nix.gc = {
    dates = lib.mkForce "Mon 05:00";
    options = lib.mkForce "--delete-older-than 30d";
    persistent = false;
  };

  # OBS records to the RAID0 scratch array (disko mounts it at /recordings,
  # root-owned by default) — the seeded profile's FilePath/RecFilePath point
  # there, so the session user must be able to write it. tmpfiles covers the
  # nofail case: if the array is absent the dir still exists on root and
  # recordings degrade to the boot disk instead of erroring out. (Files written
  # there while the array is away get shadowed under the mountpoint when it
  # returns — still eating boot-disk space; unmount to reclaim.)
  systemd.tmpfiles.rules = [
    "d /recordings 0775 ${cala-m-os.globals.defaultUser} users -"
  ];
  # tmpfiles alone races the mount: nofail mounts are NOT ordered before
  # local-fs.target (which tmpfiles-setup runs after), so on a boot where
  # tmpfiles wins, the root-owned xfs mounts OVER the chowned stub and OBS
  # gets EACCES — bites exactly once, on the first boots after a fresh
  # format, until a chown lands on the mounted fs (xfs persists it). Bind a
  # oneshot to the mount so ownership is asserted whenever it actually mounts.
  systemd.services.recordings-owner = {
    after = ["recordings.mount"];
    wantedBy = ["recordings.mount"];
    serviceConfig.Type = "oneshot";
    script = ''
      chown ${cala-m-os.globals.defaultUser}:users /recordings
      chmod 0775 /recordings
    '';
  };

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
