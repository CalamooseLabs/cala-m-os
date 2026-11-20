##################################
#                                #
#          Stream Box            #
#    headless services host      #
#   multichat  +  chat-cards     #
#      cobblemon-overlay         #
#                                #
##################################
#
# No display manager, no compositor, no desktop session: what this host does is
# done by system services that are up at boot without anybody logging in — the
# three the streamer profile enrols (multichat on :8081, chat-cards on :8787,
# cobblemon-overlay on :8082), the secrets fetch and sshd.
#
# It is managed from the LAN: over SSH (hub, the keys in
# users/streamer/public_keys) and through the services' own web pages. The
# local console is the fallback for when the network is not there: a visible
# boot menu, a verbose boot and a login prompt on tty1 (see "Headless" and
# "Boot visibility" below).
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
  #   this file (below)               -> stream-key-* (no consumer yet: for
  #                                      the mailroom module that lands next)
  calamoose.enableSecrets = "online";
  calamoose.version = "1.5.0";

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
    ++ lib.optional (!initialInstallMode) {
      services.proton-secrets.patFile = "/var/lib/proton-pass-cli/pat";

      # Secrets are best-effort on this box: a switch that could not read every
      # secret installs what it did read, keeps the previous value of the rest,
      # warns and goes through (the default would change nothing and fail the
      # switch), so a Proton hiccup or one bad vault field never blocks a
      # deploy. The boot-time unit behaves this way whatever is set here, and
      # reports through its exit code instead. What that unit can still change
      # is how a switch ENDS: switch-to-configuration lists every unit that is
      # failed, or retrying after a failure, when it finishes, and then exits
      # 4 ("the following units failed: proton-secrets-fetch.service") — the
      # new generation is active all the same; `sudo proton-secrets doctor`
      # says what the unit is unhappy about. This is not what keeps the boot
      # safe: the fetch is skipped inside the initrd whatever it is set to (the
      # gen2 "no usable init" hang, see machines/workstations/TRX50-SAGE).
      services.proton-secrets.failClosed = false;

      # Keep a sealed last-known-good copy of every secret on disk and restore
      # it before any service starts (proton-secrets-restore.service). What it
      # buys an always-on box: multichat's and chat-cards' secrets and the
      # stream keys are there at boot with the values last read from Proton,
      # without waiting for it; an expired PAT, a broken session or a Proton
      # or internet outage does not leave the stream box without them at its
      # next power cycle; and a secret rotated in Proton Pass still arrives
      # with the next successful fetch, which also restarts the units named in
      # its restartUnits.
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

      # Stream keys for The Company, Inc. — one Proton Pass item ("Stream
      # Keys", vault Cala-M-OS) with a field per destination. Declared here for
      # the mailroom module that lands next; until it does, nothing on this
      # host reads them. They are fetched, cached and reported like every
      # other secret all the same, so a wrong field shows up before there is a
      # consumer to miss it.
      # Root-only — the facade's default, root:root 0400 — and no owner: a
      # LoadCredential consumer needs none (multichat and chat-cards run as
      # DynamicUser units and take their root-only secrets that way). No
      # restartUnits either, while there is no unit to name.
      # A missing, renamed or blank field costs only that one key: the fetch
      # keeps its previous (or cached) value, installs the other secrets and
      # reports the secret by name — in `sudo proton-secrets doctor` (the
      # per-secret lines of the last fetch, each with its reason), in
      # /run/proton-secrets.status, and in `systemctl status
      # proton-secrets-fetch`, which is not active until every secret was read.
      # A switch is not stopped by it: its fetch step only warns (failClosed
      # above; the same note says when the switch still ends with exit 4). To
      # check a field without printing it — the count should be well above 1;
      # 0 or 1 means it came back empty:
      #   sudo proton-secrets resolve --vault-name Cala-M-OS --item-title 'Stream Keys' --field 'YouTube Vertical' | wc -c
      calamoose.secrets = let
        streamKey = field: {
          vaultName = "Cala-M-OS";
          itemTitle = "Stream Keys";
          inherit field;
        };
      in {
        "stream-key-twitch" = streamKey "Twitch";
        "stream-key-youtube" = streamKey "YouTube";
        "stream-key-youtube-vertical" = streamKey "YouTube Vertical";
      };
    };

  networking.hostName = "broadcast";

  # ---- Headless -----------------------------------------------------------
  # Core turns greetd on for every host (hosts/_core/configuration.nix). There
  # is no session to start here, so it is forced off — the switch `ai`,
  # `webhost` and modules/tci-server use. Without it the system boots to
  # multi-user.target and tty1 carries a plain getty: a login prompt, no
  # autologin. That prompt is the local way in when the network is not there;
  # hub logs in with the password typed at install (wiki: ISO-Installer — the
  # admin_password secret only seeds an account that is created while the
  # file is readable). Day to day the box is reached over SSH with hub's keys
  # (users/streamer/public_keys), and sudo asks for no password.
  services.greetd.enable = lib.mkForce false;

  # Physical power button: a short press is a clean shutdown. logind handles
  # the key itself and has systemd power the machine off, so every service
  # gets its stop signal and the filesystems are unmounted before the power
  # goes. That is logind's default; it is written down because this box
  # depends on it — there is no session and no screen to shut it down from,
  # and somebody standing in front of it has only this button.
  services.logind.settings.Login.HandlePowerKey = "poweroff";

  # Always on. The services here have to be there whenever a stream starts
  # and nobody sits at this box to wake it, so the machine must never put
  # itself to sleep. Nothing in the streamer profile asks for sleep, but that
  # is an absence, not a guarantee: one `systemctl suspend` or a future module
  # would take the services down until someone walked to the box. sleep.conf
  # makes every sleep verb fail instead. Coming back by itself after a power
  # cut is the other half and lives outside this repo: the firmware's
  # "restore on AC power loss" must be set to power on (after that every
  # service here starts unattended; none of them waits for a login).
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

  # The RAID0 scratch array (disko mounts it at /recordings, root-owned by
  # default) is the default user's to write, and group-writable for `users`.
  # tmpfiles covers the nofail case: if the array is absent the dir still
  # exists on root and a writer degrades to the boot disk instead of erroring
  # out. (Files written there while the array is away get shadowed under the
  # mountpoint when it returns — still eating boot-disk space; unmount to
  # reclaim.)
  systemd.tmpfiles.rules = [
    "d /recordings 0775 ${cala-m-os.globals.defaultUser} users -"
  ];
  # tmpfiles alone races the mount: nofail mounts are NOT ordered before
  # local-fs.target (which tmpfiles-setup runs after), so on a boot where
  # tmpfiles wins, the root-owned xfs mounts OVER the chowned stub and a
  # writer gets EACCES — bites exactly once, on the first boots after a fresh
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
}
