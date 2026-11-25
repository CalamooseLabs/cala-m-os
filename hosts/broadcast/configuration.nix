##################################
#                                #
#          Stream Box            #
#   headless GPU mailroom host   #
#  mailroom + multichat + cards  #
#      cobblemon-overlay         #
#                                #
##################################
#
# No display manager, no compositor, no desktop session: what this host does is
# done by system services that are up at boot without anybody logging in.
# mailroom is the production: its own OBS, composited on the RTX PRO 4000 in
# an X server inside its unit, takes the feeds in and sends the show to Twitch
# and YouTube (modules/mailroom has how it works and the ports). Beside it run
# multichat (:8081), chat-cards (:8787), cobblemon-overlay (:8082), the secrets
# fetch and sshd.
#
# It is managed from the LAN:
#   http://10.2.10.2:8740/   mailroom's dashboard, day to day
#   ssh hub@10.2.10.2        the keys in users/streamer/public_keys;
#                            `sudo mailroom-ctl connect` prints every address,
#                            password and the dashboard token
# The local console is the fallback for when the network is not there: a
# visible boot menu, a verbose boot and a login prompt on tty1 (see "Headless"
# and "Boot visibility" below).
#
# ── A stream day ────────────────────────────────────────────────────────────
#   The phone (or an IRL encoder) publishes to the ingest "live": the SRT line
#   from `mailroom-ctl connect`. Its remote-control app (Moblin: OBS remote
#   control) takes ws://10.2.10.2:4455 with the password on the dashboard,
#   "Ingest" as the main scene and "live" as the source. From outside the LAN
#   neither reaches the box until the router forwards the ports (publicHost
#   below).
#   battlestation publishes its game feed to the ingest "battlestation" (OBS
#   there: Settings > Stream > Custom, the server and stream key from
#   `mailroom-ctl connect`). In mailroom's OBS that feed is the source
#   "battlestation"; the studio scene made from it is built once by hand
#   (modules/mailroom, "How a feed gets in").
#   On the dashboard: Rehearse (nothing public: Twitch gets its bandwidth
#   test, YouTube nothing), Go live, the scene buttons, End stream.
#   YouTube's vertical stream is per broadcast: in YouTube Studio's Live
#   Control Room turn on dual stream with Encoder as the vertical source and
#   the vertical key, press Arm on the dashboard, then go live. A show started
#   without it carries no vertical and says so.
#   After a power cut the box comes back OFF the air (resumeAfterReboot is
#   off): somebody presses Go live again.
#
# ── Rebuilding ──────────────────────────────────────────────────────────────
#   cd /etc/nixos && git pull
#   sudo nixos-rebuild switch --flake .#broadcast
# As root, because only root's nix holds the GitHub token for the private
# mailroom input ("The private mailroom input" below). A switch does not end a
# running show: mailroomd picks it up again from its state file, MediaMTX only
# reloads its configuration, and OBS is not restarted at all — the dashboard
# shows "OBS update pending" and mailroom restarts OBS itself once nothing is
# on the air. Rebuild off air all the same: a switch that brings a new
# MediaMTX package does restart MediaMTX, and every feed has to reconnect.
#
# NOT `switch` when the NVIDIA driver or the kernel changes — which is what a
# bump of the main `nixpkgs` pin does on this machine:
#   sudo nixos-rebuild boot --flake .#broadcast && sudo systemctl reboot
# A switch would leave the old kernel module loaded under new user-space
# libraries that refuse to talk to it: OBS keeps running, but its next start
# falls back to software rendering on x264 and the dashboard says "Reboot
# needed". Off air, "Reboot server" on the dashboard's GPU card does the
# reboot without SSH.
#
# ── First deploy, and the bring-up on the machine ───────────────────────────
# Nothing of the GPU path has run on this machine yet. The configuration below
# is where mailroom's guide (docs/GPU.md, "The way there") says to START;
# every further step is unlocked by a level of its validation kit passing ON
# THE BOX, and is marked NEXT below with the check that unlocks it. The order
# (the guide's section 9, "Bring-up"; each level prints what to prepare):
#    1. The first deploy comes from devbox, as root (step b below), with
#       `boot`, then a reboot.
#    2. sudo mailroom-gpu-check --level quick,host     everything PASS or SKIP
#    3. sudo mailroom-gpu-check --level nvenc          off air; N02: room for
#                                                      the 1440p60 plan?
#    4. obs.gpu.kit.dualFormatCheck = true, switch, then inside tmux with
#       inspector.twitch.tv open:
#       sudo mailroom-gpu-check --level stock-twitch   T01: Enhanced
#                                                      Broadcasting, T02: Dual
#                                                      Format
#    5. sudo mailroom-gpu-check --level display        the OBS desktop closed;
#       D01-D04, then raise the canvas (NEXT), switch, run it again
#    6. sudo mailroom-gpu-check --level outputs        inside tmux
#    7. sudo mailroom-gpu-check --level youtube        needs the test keys
#                                                      (NEXT); Y02: HEVC, Y03
#    8. twitch.encode = "enhanced" (NEXT), switch,
#       sudo mailroom-gpu-check --level twitch         W01-W04; W05 with Dual
#                                                      Format
#    9. sudo mailroom-gpu-check --level uplink         uploads stopped, the
#       test keys in and network.uplinkMbps set (both NEXT); U01
#   10. sudo mailroom-gpu-check --level soak           4 hours, ISO on
#   11. The reboot test (Reboot server on the dashboard, or `sudo systemctl
#       reboot`, off air): within two minutes everything is back without a
#       hand on it, and nothing is live (checklist l is the same reboot with
#       something running). Then a rehearsal against the real platforms, and
#       one before each show.
#   12. The reports stay in /var/lib/mailroom/gpu-check; run quick again after
#       every driver change.
# The off-air levels refuse to run while anything is live or recording. Over
# SSH run them inside tmux (installed for this), so a dropped connection does
# not cut a run short.
#
# ── First-boot checklist (what could not be checked off the box) ────────────
#   a. Before the first deploy. On the box, the three stream-key fields come
#      back: a missing or blank one now keeps mailroomd, and the dashboard
#      with it, from starting ("Stream keys" below). For each of 'Twitch',
#      'YouTube' and 'YouTube Vertical', a count well above 1:
#        sudo proton-secrets resolve --vault-name Cala-M-OS --item-title 'Stream Keys' --field 'Twitch' | wc -c
#      (`resolve` is also in the generation the box runs today; `sudo
#      proton-secrets doctor`, which lists every secret of the last fetch,
#      arrives with this one.) On devbox, where the first deploy is built,
#      root's nix can read the private input:
#        sudo nix flake metadata github:CalamooseLabs/mailroom
#      prints the flake's description and a Locked URL, not an HTTP 404
#      ("The private mailroom input" below says what to change when it is a
#      404).
#   b. The first deploy cannot be made on the box: evaluating this
#      configuration already needs the private input, and the token that
#      fetches it is delivered by the very generation being built (the box has
#      no git yet either). From devbox, whose root nix holds its own copy of
#      the token — the route hosts/tci-cloud uses for its updates:
#        sudo --preserve-env=SSH_AUTH_SOCK nixos-rebuild boot --flake .#broadcast \
#          --target-host hub@10.2.10.2 --sudo
#        ssh hub@10.2.10.2 sudo systemctl reboot
#      (devbox builds the system, the NVIDIA modules for this box's kernel
#      included, and copies it over.)
#   c. After the reboot, on the box:
#        systemctl status mailroom-secrets mailroom-auth mailroom-mediamtx \
#          mailroomd mailroom-obs mailroom-twitch-relay.socket \
#          mailroom-gpustat nvidia-persistenced
#      all active (mailroom-secrets: "active (exited)"), and
#        sudo mailroom-ctl status
#      says "off air", a "rendering" line with "(the card)" and "encoder
#      plan nvenc" — not SOFTWARE, not x264 — and no REBOOT NEEDED.
#      A mailroomd that is still "activating" after a minute is most likely
#      waiting for a stream key: `sudo proton-secrets doctor` lists every
#      secret of the last fetch, each with its reason.
#   d. The token now works on the box itself (afterwards "Rebuilding" above
#      is all it takes):
#        sudo nix flake metadata github:CalamooseLabs/mailroom
#      prints the flake's description and a Locked URL, not an HTTP 404.
#   e. This pin's OBS is 32.1.2; mailroom was verified with 32.2.2, and its
#      module warns about that at every evaluation. Mailroom's two flake
#      checks that tie it to an OBS (obs-mailroom's own tests, and
#      relay-obs-compat: OBS's code reading the Twitch relay's answers) do
#      build and pass against 32.1.2; the plugin inside the running OBS on
#      the card is what they cannot show. The kit's quick level (step 2)
#      must show Q07 PASS (mailroom's OBS plugin answers) and Q13 PASS (NVENC
#      registered); the dashboard's Outputs card must read "running:
#      single", with no alert "obs-mailroom unavailable". If the
#      plugin does not load, mailroom falls back to one encode for every
#      destination, without the vertical: then take OBS from the beta pin as
#      well (calamoose.beta.packages in modules/mailroom gains "obs-studio":
#      32.2.2, the verified one; the NVIDIA driver and the kernel stay where
#      they are).
#      One habit of 32.1.2 to know when reading `journalctl -u mailroom-obs`:
#      now and then it ends in "Trace/breakpoint trap" while it is being
#      STOPPED (seen off the box, in software rendering, about one stop in
#      five; an OBS 32.2.2 did not do it). The scene collection is saved
#      before that point and mailroom's launcher treats a requested stop as
#      clean either way, so nothing follows from it.
#   f. The two cards: the AMD card drives the console (the KVM), mailroom's
#      X server must take the NVIDIA one. The display level's D01 (step 5)
#      settles it; `sudo cat /run/mailroom-obs-state/renderer.json` shows
#      "mode": "nvidia-xorg" and an adapter naming the RTX PRO 4000.
#   g. A feed gets in. `sudo mailroom-ctl connect`, its SRT line for "live"
#      into the phone's encoder: `sudo mailroom-ctl status` then reads
#      "ingest live (main): online, … kbps". The same from battlestation's
#      OBS with the RTMP server and stream key of "battlestation": "ingest
#      battlestation: online". (That is the generated password, the auth
#      hook and the firewall in one go.)
#   h. The overlays under NVIDIA's X server: the dashboard's program picture
#      shows the chat column and, after `multichat fake follow --port 8081`
#      on the box, an alert; `sudo mailroom-ctl status` counts the overlay
#      pages that answer. OBS's browser draws pages on the CPU here (mailroom
#      starts it with the browser's hardware acceleration off); a blank
#      overlay whose service is up is the thing to report.
#   i. The software fallback: the display level's D05 (step 5) switches to
#      software rendering and back, and says whether this CPU keeps up.
#   j. From another device on the LAN: http://10.2.10.2:8740/ asks for the
#      token and opens. A 403 "host not allowed" means the name or address in
#      the browser is not one the dashboard answers to (api.allowedHosts
#      below; 10.2.10.2 itself is the router's DHCP reservation for this
#      box, see calamoose.mailroom.lanAddress). Then, off air, Restart OBS on
#      the dashboard's GPU card: OBS is back within about a minute. "Access
#      denied" there is polkit not letting mailroomd restart the unit, and
#      with it every recovery button of the dashboard: `journalctl -u polkit`.
#   k. multichat hears mailroom: start and end a rehearsal, then
#        sudo mailroom-ctl status      "webhook multichat: … delivered", no FAILING
#        multichat live --port 8081    "go-live boost: idle · 0/12 used today"
#      A rehearsal is not a public start, so nothing is looked for. After the
#      first real go-live the second line reads "go-live boost: ACTIVE …".
#      (A dropped event or two from a boot in which multichat came up after
#      mailroomd is no fault: the state is sent again.)
#   l. Nothing comes back on the air by itself: start a rehearsal, then
#        sudo systemctl reboot
#      (the dashboard's Reboot server refuses while one runs). After the boot
#      `sudo mailroom-ctl status` says "off air", and the dashboard's activity
#      log has "the server went down while rehearsing: not resumed after the
#      reboot".
#   m. The scratch array:
#        findmnt /recordings ; sudo ls -ld /recordings/mailroom-iso
#      an xfs on /dev/md…, and the directory mailroom:mailroom, drwxr-x---.
#   n. The console: at the KVM, log in as hub on tty1. That password is the
#      one typed at install; with no network it is the only way in.
#   o. The firmware: "restore on AC power loss" set to power on, or a power
#      cut leaves the box off until somebody walks to it. Cut the power once,
#      off air, to see it come back by itself.
#
# ── Firewall ────────────────────────────────────────────────────────────────
# Opened by this change, next to sshd's 22, multichat's 8081 and chat-cards'
# 8787 (and 8082 for battlestation alone):
#   TCP  1935  RTMP ingest          UDP  8890  SRT ingest
#   TCP  4455  obs-websocket gateway
#   TCP  8740  mailroom's dashboard and API
# Nothing else of mailroom's is reachable: OBS's own websocket (4460) listens
# on every interface but is not opened, the rest is on loopback. No VPN, no
# reverse proxy, no TLS: this is a LAN box, and what reaches it from outside
# is the UniFi router's to decide.
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
  #   modules/nix-github-token        -> nix-github-token (the access-tokens
  #                                      line in root's nix.conf, for the
  #                                      private mailroom input)
  #   this file (below)               -> stream-key-* (mailroomd: the keys of
  #                                      the three destinations)
  # mailroom's ingest passwords and dashboard token are NOT here: the box
  # generates them itself (modules/mailroom, mailroom-secrets.service).
  calamoose.enableSecrets = "online";

  # 2.0.0: the box changes roles. 1.x was the desktop production and then the
  # headless services host; from here on it is the GPU mailroom host. The
  # label (`cat /run/current-system/nixos-version`, and the boot-menu entry)
  # starts with cala-2.0.0 once this configuration is the one that booted.
  calamoose.version = "2.0.0";

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
  # the definition entirely there. Everything of mailroom's rides the same
  # block: its options, and the modules that declare them, exist only in the
  # full configuration.
  imports =
    [
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
        # nix-github-token = the PAT that lets Nix fetch the PRIVATE mailroom
        # flake input at eval time (keyed by the user PROFILE, as on tci-cloud).
        extra_user_modules = {streamer = ["nix-github-token"];};
      })
    ]
    ++ lib.optional (!initialInstallMode) ({config, ...}: {
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

      # ---- The private mailroom input ---------------------------------------
      # CalamooseLabs/mailroom is a PRIVATE repository, so nix needs a GitHub
      # token to evaluate this host at all. The secrets facade fetches Proton
      # item nix-github-token (vault Cala-M-OS, field secret — the module's
      # defaults, the item tci-cloud reads) to /run/proton-secrets/
      # nix-github-token and nix.conf !includes it. The file is root's, 0400:
      # ROOT's nix on this box fetches the input, which is why rebuilds here
      # are `sudo nixos-rebuild` (header, "Rebuilding").
      # The item's line was written for the private repositories of another
      # GitHub organisation (The-Company-Inc-Nerds: bookkeeper,
      # cobblemon-initiative). It now also has to open CalamooseLabs/mailroom,
      # and so does devbox's own copy of the line, the agenix file
      # modules/nix-github-token/secrets/nix-github-token.age, which is what
      # the first deploy is built with. Whether they can is the owner's to
      # check (checklist a and d). A fine-grained GitHub token belongs to ONE
      # owner and cannot be given a repository of a second one: if that is
      # what the line holds, it needs either a classic token (scope repo) of
      # an account that is in both organisations, or one fine-grained token
      # per owner, which nix picks by the owner in the entry's name (write
      # the owners as flake.nix does):
      #   access-tokens = github.com/The-Company-Inc-Nerds=github_pat_… github.com/CalamooseLabs=github_pat_…
      # The installer's cala-nix-token takes a line with several entries too.
      # modules/nix-github-token has the rest about the line.
      # A box that is ever reinstalled goes through `sudo cala-reinstall`,
      # which carries this box's own token line and its Proton PAT into the
      # installer, and installs the DEFAULT branch — merge first.
      programs.nix-github-token.enable = true;

      # ---- Stream keys ------------------------------------------------------
      # Stream keys for The Company, Inc. — one Proton Pass item ("Stream
      # Keys", vault Cala-M-OS) with a field per destination, read by mailroomd
      # as the keys of its three destinations (below).
      # Root-only: no owner, group or mode is set, so the facade passes none on
      # and the backend's default applies, root:root 0400. mailroomd takes them
      # through LoadCredential=, which systemd reads as root when the unit
      # starts.
      # That makes them start-up requirements: while ONE of the three files is
      # missing mailroomd does not start, and with it the dashboard and stream
      # control are down (it retries every 3 s, for as long as it takes, and
      # comes up within seconds of the file appearing). On this box the files
      # are restored from the sealed cache before any service starts, so that
      # is the state only of a key that was never read at all: a missing,
      # renamed or blank field. The fetch reports such a secret by name — in
      # `sudo proton-secrets doctor` (the per-secret lines of the last fetch,
      # each with its reason), in /run/proton-secrets.status, and in
      # `systemctl status proton-secrets-fetch`, which is not active until
      # every secret was read. A switch is not stopped by it: its fetch step
      # only warns (failClosed above). To check a field without printing it —
      # the count should be well above 1; 0 or 1 means it came back empty:
      #   sudo proton-secrets resolve --vault-name Cala-M-OS --item-title 'Stream Keys' --field 'YouTube Vertical' | wc -c
      #
      # restartUnits: a key replaced in Proton Pass arrives with the next
      # fetch (a boot, a switch, `sudo proton-secrets refresh`), and the fetch
      # then restarts mailroomd, which reads its credentials only when it
      # starts. A restart of mailroomd does not end a running show (mailroom's
      # README, "Restarts, reboots and late secrets"), but the destination
      # whose key changed has to connect anew with it: replace keys off air.
      # No ordering onto the fetch unit, as for every consumer
      # (modules/secrets).
      calamoose.secrets = let
        streamKey = field: {
          vaultName = "Cala-M-OS";
          itemTitle = "Stream Keys";
          inherit field;
          restartUnits = ["mailroomd.service"];
        };
      in {
        "stream-key-twitch" = streamKey "Twitch";
        "stream-key-youtube" = streamKey "YouTube";
        "stream-key-youtube-vertical" = streamKey "YouTube Vertical";
      };

      # ---- The NVIDIA card, as mailroom's GPU guide wants the host ----------
      # machines/modules/nvidia-gpu (shared with the other NVIDIA machines)
      # already gives this one what the guide's section 1 asks first: the
      # driver selected with no X server or display manager on the host, the
      # OPEN kernel modules (the only ones a Blackwell card runs on),
      # modesetting, and nvidiaPackages.stable — on this pin 595.80, the
      # production branch the guide names. What it lacks or sets otherwise is
      # set here, for this host only:
      hardware.nvidia = {
        # Asserted by mailroom's module. Keeps the card initialised between
        # OBS starts: OBS's own NVENC check gives up after 2.5 s, a cold GPU
        # can take longer, and OBS would then run without NVENC.
        nvidiaPersistenced = true;
        # nixpkgs turns it on by default and mailroom's module warns while it
        # is: nvidia-vaapi-driver only decodes, and OBS does not use it.
        videoAcceleration = false;
        # The settings GUI of a desktop; there is no session to open it in.
        # (The shared module turns it on, hence the force.)
        nvidiaSettings = lib.mkForce false;
      };
      # 32-bit GL is for Steam and Wine. Both GPU modules ask for it because
      # their other machines game; nothing in the streamer profile is a 32-bit
      # program, and the guide's host has none. Off, the driver's 32-bit half
      # leaves the closure, one thing less to line up at a driver change.
      hardware.graphics.enable32Bit = lib.mkForce false;
      # (machines/modules/amd-gpu stays as it is: the AMD card is the
      # console's, and its /dev/dri/amd-* symlinks are inert without a
      # compositor to pin.)

      # ---- /recordings: the scratch array, for mailroom's ISO takes ---------
      # The RAID0 array (disko mounts it at /recordings, nofail) holds the ISO
      # recordings: each ingest as it arrived, for the edit — disk, not CPU,
      # about 0.45 GB per hour for every Mbit/s of a feed. The PROGRAM
      # recording is not here: with Twitch on its own encode MediaMTX writes it
      # to /var/lib/mailroom/recordings on the boot disk and deletes it after a
      # day (recording.deleteAfter).
      #
      # nofail means the array is not ordered before local-fs.target, and may
      # be missing altogether. Three things follow:
      #   - tmpfiles alone would race the mount: a directory it made on the
      #     boot disk is covered when the array mounts over it. So the
      #     directory is asserted by a unit bound to the mount, and only when
      #     /recordings really is a mount point. It also takes the array's
      #     root back from hub, whose scratch disk it was for the desktop OBS.
      #   - mailroom's units are ordered AFTER the mount — ordered, not
      #     dependent: with the array there they start once it is mounted (so
      #     their sandboxes see the real directory), with a member missing
      #     they start once the device timeout has passed (30 s, disko.nix).
      #     The stream is never held up for a recordings disk.
      #   - without the array ISO does not stop: mailroom's own tmpfiles rule
      #     makes the directory on the boot disk and the takes land there,
      #     within maxSizeGB and never below 5 GB free. Once the array is back
      #     (reboot off air) they sit hidden under the mount point;
      #     `sudo umount /recordings`, off air, shows them.
      systemd.tmpfiles.rules = ["d /recordings 0755 root root -"];
      systemd.services.mailroom-recordings = let
        m = config.services.mailroom;
      in {
        description = "Mailroom: the ISO directory on the scratch array";
        wantedBy = ["recordings.mount"];
        after = ["recordings.mount"];
        before = ["mailroom-mediamtx.service" "mailroomd.service" "mailroom-obs.service"];
        unitConfig.ConditionPathIsMountPoint = "/recordings";
        serviceConfig.Type = "oneshot";
        script = ''
          chown root:root /recordings
          chmod 0755 /recordings
          install -d -m 0750 -o ${m.user} -g ${m.group} ${m.recording.iso.directory}
        '';
      };
      systemd.services.mailroom-mediamtx.after = ["recordings.mount"];
      systemd.services.mailroomd.after = ["recordings.mount"];
      systemd.services.mailroom-obs.after = ["recordings.mount"];

      # ---- mailroom on this host ----------------------------------------------
      # modules/mailroom has what any host would want (the LAN dashboard, the
      # generated secrets, the overlays, multichat's hint). Here: this box's
      # addresses, its second feed, the card, and the three destinations.
      calamoose.mailroom = {
        # 10.2.10.2 (settings.nix). Nothing here assigns it: the box is on
        # DHCP and the address is the router's reservation for it. It is
        # baked into what `mailroom-ctl connect` and the dashboard's connect
        # panel print and into the names the dashboard answers to, so a box
        # that comes up under another address still takes feeds and SSH
        # there, but its dashboard answers 403 "host not allowed" until the
        # reservation (or settings.nix) is put right.
        lanAddress = cala-m-os.ip.studio.broadcast;
        # battlestation's game feed over the LAN — what the HDMI capture card
        # was for the desktop OBS. A feed of its own, with its own password;
        # it never drives the automatic switching (that is "live").
        extraIngests = ["battlestation"];
      };

      services.mailroom = {
        # publicHost stays the LAN address (the module's default): it is what
        # the dashboard's connect panel and the guest invites print for
        # encoders. Once the router forwards the ingest ports (8890/udp, and
        # 1935/tcp for RTMP) under a public name, set that name here; the
        # dashboard keeps answering to the LAN address, and `mailroom-ctl
        # connect` then prints the strings for both.
        # publicHost = "<public name>";

        # More names the dashboard answers to, besides the LAN address and the
        # bare host name (modules/mailroom). Each is a name the LAN's resolver
        # has to serve for this box before it does anything; a browser that
        # uses another one gets 403 "host not allowed" (checklist j).
        api.allowedHosts = ["broadcast.local" "broadcast.calamos.family"];

        obs = {
          # OBS composites on the card and encodes with NVENC; when the GPU
          # path fails it falls back to software rendering by itself and says
          # so on the dashboard, until "Try GPU again" or a reboot.
          gpu.enable = true;

          # START: 1920x1080 at 30 fps in H.264 — the guide's starting canvas,
          # and all the software fallback can carry anyway.
          # NEXT (display level, D01-D04 pass at this canvas):
          #   video = { width = 2560; height = 1440; fps = 60; };
          #   then switch and run the display level again. The overlays keep
          #   their place: OBS scales every item with the canvas.
          # NEXT (youtube level, Y02 — needs the test keys below):
          #   video.codec = "hevc";
          video = {
            width = 1920;
            height = 1080;
            fps = 30;
            codec = "h264";
          };

          # The portrait canvas (1080x1920) for YouTube's vertical stream, and
          # later Twitch's Dual Format. The guide allows it from the start: it
          # is only drawn on the card with NVENC, and its destination is
          # paused, and says so, whenever OBS is in software rendering.
          # NEXT (nvenc level, only if N02 says NVENC is short of headroom):
          #   vertical.fpsDivisor = 2;
          vertical.enable = true;

          # NEXT (bring-up step 4, for the stock-twitch run only; it compiles
          # the kit's patched Aitum Vertical on the box, and can go again
          # afterwards):
          #   gpu.kit.dualFormatCheck = true;
        };

        destinations = {
          # Twitch on an encode of its own: one 1080p H.264 track at 6000
          # kbps, while the program goes to YouTube at YouTube's own rate
          # (10000 kbps at 1080p30). In a rehearsal Twitch gets the real key
          # as a bandwidth test, which it measures and never shows.
          # NEXT (stock-twitch T01, then the twitch level's W01-W04 in a
          # rehearsal): twitch.encode = "enhanced" — Twitch's Enhanced
          #   Broadcasting, the ladder Twitch answers (2K once the canvas is
          #   2560x1440). The relay then loads the key too, so the Twitch key
          #   above becomes
          #     "stream-key-twitch" = streamKey "Twitch" // {restartUnits =
          #       ["mailroomd.service" "mailroom-twitch-relay.service"];};
          # NEXT (T02 and W05, with "enhanced"): twitch.dualFormat = true;
          twitch = {
            platform = "twitch";
            streamKeyFile = config.calamoose.secrets."stream-key-twitch".path;
            twitch.encode = "single";
          };

          # YouTube gets the program. In YouTube Studio set the key's
          # resolution to Variable: it changes with the canvas, and on a
          # fallback to software rendering. A rehearsal skips YouTube until it
          # has a test key (below).
          youtube = {
            platform = "youtube";
            streamKeyFile = config.calamoose.secrets."stream-key-youtube".path;
          };

          # YouTube's second (Encoder) key: the vertical canvas's stream; a
          # key of its own, set to Variable resolution like the main one.
          # Armed per broadcast (the default for it): YouTube takes the
          # vertical only when the broadcast was set up for it before it
          # started, so it is off until Arm is pressed, off air.
          # NEXT (youtube level, Y03, if YouTube keeps Encoder selected from
          # one broadcast to the next): arm = "always";
          youtube-vertical = {
            platform = "youtube";
            feed = "vertical";
            streamKeyFile = config.calamoose.secrets."stream-key-youtube-vertical".path;
          };
        };

        # ISO: every ingest recorded as received, while live (the default
        # mode), onto the scratch array. 200 GB is the guide's starting
        # budget; the oldest takes go first, and everything after 7 days.
        # NEXT (soak level, S1, and a real show's worth of takes): size
        # maxSizeGB to the array — battlestation's feed weighs far more than
        # the phone's.
        recording.iso = {
          enable = true;
          directory = "/recordings/mailroom-iso";
          maxSizeGB = 200;
        };

        # NEXT (before the uplink level; U01 measures the real figure): the
        # line's sustained upload in Mbit/s. The dashboard then compares what
        # the show plans to send against it.
        #   network.uplinkMbps = <Mbit/s>;
      };

      # ---- Left out until their secrets exist --------------------------------
      # Two things the guide's configuration has need vault entries nobody has
      # made yet. Both are written as OPTIONAL secrets, so a missing item is
      # reported by the fetch and never fails it — but mailroomd loads each as
      # a credential, and does not start while a declared file is missing.
      # So: create the field first, check it (the `resolve … | wc -c` line
      # above), and only then add the lines, inside this block.
      #
      # YouTube's rehearsal keys. With them a rehearsal sends YouTube's main
      # and vertical streams to a private test broadcast instead of skipping
      # YouTube, the kit's youtube level has something to check (it leaves
      # out a YouTube destination that rehearsals skip) and its uplink level
      # measures the line (without them it sends to the kit's own sinks on
      # loopback: the encoders, not the uplink). That is what unlocks HEVC
      # (Y02) and arm = "always" (Y03). In YouTube Studio: a private test
      # broadcast with dual stream on, Encoder as its vertical source, and two
      # keys of its own, both set to Variable resolution; the keys go into two
      # new fields of the "Stream Keys" item.
      #   calamoose.secrets."stream-key-youtube-test" = {
      #     vaultName = "Cala-M-OS"; itemTitle = "Stream Keys"; field = "YouTube Test";
      #     optional = true; restartUnits = ["mailroomd.service"];
      #   };
      #   calamoose.secrets."stream-key-youtube-vertical-test" = {
      #     vaultName = "Cala-M-OS"; itemTitle = "Stream Keys"; field = "YouTube Vertical Test";
      #     optional = true; restartUnits = ["mailroomd.service"];
      #   };
      #   services.mailroom.destinations.youtube.rehearsal = {
      #     mode = "testKey";
      #     streamKeyFile = config.calamoose.secrets."stream-key-youtube-test".path;
      #   };
      #   services.mailroom.destinations.youtube-vertical.rehearsal = {
      #     mode = "testKey";
      #     streamKeyFile = config.calamoose.secrets."stream-key-youtube-vertical-test".path;
      #   };
      #
      # The alert webhook. mailroom's alerts (a destination down, a fallback
      # to software rendering, NVENC gone, Reboot needed, the ISO disk) show
      # on the dashboard either way; with a webhook they also reach a phone
      # nobody is holding the dashboard on. The secret is the whole URL of a
      # private ntfy topic (or a Discord webhook, format = "discord").
      #   calamoose.secrets."mailroom-alert-url" = {
      #     vaultName = "Cala-M-OS"; itemTitle = "mailroom-alert-url"; field = "secret";
      #     optional = true; restartUnits = ["mailroomd.service"];
      #   };
      #   services.mailroom.alerts.webhook = {
      #     urlFile = config.calamoose.secrets."mailroom-alert-url".path;
      #     format = "ntfy";
      #   };
    });

  networking.hostName = "broadcast";

  # ---- Headless -----------------------------------------------------------
  # Core turns greetd on for every host (hosts/_core/configuration.nix). There
  # is no session to start here, so it is forced off — the switch `ai`,
  # `cala-web` and modules/tci-server use. Without it the system boots to
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
