##################################
#                                #
#  TCI Cloud Server (public)     #
#  Hetzner Cloud CCX33 (US)      #
#  5.78.214.170                  #
#                                #
#  The Cobblemon Initiative      #
#  PUBLIC multiplayer fleet: no  #
#  whitelist, hub + warden + up  #
#  to ten worlds at once, solo   #
#  or co-op groups of up to      #
#  four on terms they choose.    #
#  Runs itself: no operator in   #
#  the loop. 8 vCPU / 32 GB /    #
#  240 GB.                       #
#                                #
##################################
#
# What this box is: the OPEN Cobblemon Initiative server. The cagelocke event
# it was first deployed for is over (2026-11) and the same CCX33 is rebuilt
# from scratch as a public fleet: anyone carrying the pack may join — no hub
# whitelist, no provisioning allowlist — and TheCalamoose is the only op.
# Nobody runs it day to day. Every dead end a player can reach is one they can
# leave by themselves: that is what the mod module's PUBLIC FLEET knobs set
# below are for (their manual is the header of nix/tci-server.nix in the
# cobblemon-initiative repo; the players' side is that repo's wiki page
# Development-Multiplayer-Server).
#   The player flow, in three lines:
#     1. Join 5.78.214.170 with the multiplayer pack. The lobby greets every
#        joiner with clickable [Play solo] [Co-op venture] [Status].
#     2. Solo: /tci-hub play boots your own world and transfers you into it.
#        Co-op: /tci-hub coop invite <name> (up to four); the founder sets the
#        terms — soul link (ONE health bar and ONE hunger bar, one death ends
#        it for all) or none (a fallen colleague can be revived within 120 s,
#        else the run fails for the group), PvP, trading & battling — everyone
#        agrees, the founder signs, and /tci-hub play boards the whole group.
#        Three starters, four seats: the fourth to choose gets 30 Poké Balls.
#     3. A run that ends by death walks its players back to the lobby by itself
#        (solo: some ten seconds after the death) and the next /tci-hub play
#        starts a fresh world. /tci-hub abandon | coop leave | coop disband end
#        a world or a group for good — no operator.
#
# Deploy from devbox at /etc/nixos, or from the box itself. The cobblemon-
# initiative input is a PRIVATE repo: on devbox only root's nix holds the GitHub
# token for it (modules/nix-github-token), so the devbox commands below run under
# sudo (--preserve-env=SSH_AUTH_SOCK lets root's ssh use your agent's YubiKey
# key). The box holds the SAME token itself: enableSecrets = "online" fetches it
# from Proton Pass into root's nix.conf (see below), so once installed it can
# `nixos-rebuild` straight from github:CalamooseLabs/cala-m-os and reinstall
# itself with no flags. Both need the Proton Pass PAT on the box; the first
# install seeds it (step 3).
#
#   First install (no custom ISO, no support ticket):
#     1. Create the server (x86 CCX, any placeholder image) with NO Volumes
#        attached, so the root disk is the only /dev/sdX (HETZNER-CLOUD/disko.nix).
#     2. `publicHost` below is the box's IPv4 literal (5.78.214.170): nothing to
#        resolve. When play.thecompany.inc gets an A record pointing at it
#        (`dig +short play.thecompany.inc @1.1.1.1`), switch publicHost AND the
#        client pack's --server-address to the name; the AAAA record only
#        after step 4.
#     3. Enable Rescue (linux64) with your SSH key, reset into it, and check the
#        box boots UEFI — this layout needs it, CCX servers do, the CX line does
#        not: `ls /sys/firmware/efi` in the rescue shell (and `lsblk` that
#        /dev/sda is the only disk). Then run:
#          mkdir -p extra/var/lib/proton-pass-cli
#          (umask 077; printf '%s' 'pst_…' >extra/var/lib/proton-pass-cli/pat)
#          sudo --preserve-env=SSH_AUTH_SOCK nix run github:nix-community/nixos-anywhere -- \
#            --flake .#tci-cloud --target-host root@5.78.214.170 \
#            --extra-files ./extra \
#            --generate-hardware-config nixos-generate-config \
#              ./machines/workstations/HETZNER-CLOUD/hardware-configuration.nix
#          rm -rf extra; ssh-keygen -R 5.78.214.170
#        (The PAT is a Proton Pass Personal Access Token granted the Cala-M-OS
#        vault, the one build-pat-iso / flash-iso --with-pat take. --extra-files
#        lands it at /var/lib/proton-pass-cli/pat, root 0600, BEFORE nixos-install
#        runs this config's activation, which fetches admin_password and
#        nix-github-token fail-closed: with no PAT and no session that activation
#        aborts before the users snippet and the install fails. The alternative is
#        the PAT-bearing installer, build-pat-iso or cala-reinstall on a box that
#        already holds the PAT, which seeds the same file (wiki: ISO-Installer).
#        --generate-hardware-config replaces the placeholder profile with the
#        real box's — commit it. Never rerun nixos-anywhere on an installed box
#        by accident: it wipes the disk; updates go through nixos-rebuild below.)
#        If the kexec step fails with "Address not available" (a kernel 7.0
#        rescue kernel), add `--kexec-extra-flags -c`.
#        nixos-anywhere kexecs the rescue system into a NixOS installer, applies
#        this host's disko layout and installs the FULL config in one pass. The
#        box comes up on DHCP (calamoose.hetznerCloud, both addresses null).
#     4. Pin the addresses: ipv4Address = "5.78.214.170" (DHCP off) and the
#        IPv6 /64 from the Cloud Console into ipv6Address below, redeploy, and
#        confirm `curl -6 https://ifconfig.co` works from the box. Only then
#        publish the AAAA record.
#   Updates — from devbox:
#     sudo --preserve-env=SSH_AUTH_SOCK nixos-rebuild switch --flake .#tci-cloud \
#       --target-host hub@5.78.214.170 --sudo
#   or on the box, whose root nix.conf !includes the token Proton Pass hands it
#   (/run/proton-secrets/nix-github-token, fetched at boot by
#   proton-secrets-selfheal; `journalctl -u proton-secrets-selfheal` if a private
#   fetch is refused):
#     ssh hub@5.78.214.170 sudo nixos-rebuild switch \
#       --flake github:CalamooseLabs/cala-m-os#tci-cloud
#   A switch that changes the warden's config restarts the warden (new caps
#   apply at once) but never the hub or a running world: both are
#   restartIfChanged = false and read their marker and JVM flags at launch.
#   After changing a hub-side knob (greeting, coop.terms, selfService,
#   clientGate) restart the hub when the lobby is quiet; worlds pick
#   everything up as they next start.
#   The game bundle: the box builds it ITSELF (services.tci-server.bundleBuild,
#   the mod module's BUNDLE BUILD) from the flake input that pins the mod — the
#   repo's own `gradle build` + build_mrpack.py --profile server pipeline runs on
#   the box into /srv/tci/bundle-<version>-<source id>/ and flips /srv/tci/bundle.
#   A fresh box's hub waits for the first build (tci-bundle-ready), so a new
#   install needs no deploy step, and the bundle needs no GitHub fetch of its
#   own (the ~2 GB source travels inside the system closure). Whatever the pin
#   moves to gets its first full build ON THIS BOX — and the public co-op code
#   of mod 1.0.21 its first real play: watch that build, and walk the player
#   flow once yourself before the address circulates.
#     ssh hub@5.78.214.170 'journalctl -fu tci-bundle-build'   # the first build also
#                                                   # downloads Maven/Modrinth/Fabric deps
#     ssh hub@5.78.214.170 sudo tci-bundle status   # pinned source, live link, pin, bundles
#   New game version = move the pin and redeploy: on devbox
#     sudo nix flake update cobblemon-initiative && <an Updates command above>
#   The switch returns at once and the box rebuilds in the background; the hub
#   and running worlds keep their bundle until restarted:
#     ssh hub@5.78.214.170 sudo systemctl restart tci-server-hub   # when the lobby is quiet
#   (`sudo tci-bundle build --restart-hub` does both by hand; `tci-bundle use
#   <dir>` pins the link to a kept bundle — a rollback — and `tci-bundle unpin`
#   follows new builds again.) Only a switch issued while the FIRST build is
#   still running waits for it, through the hub. scripts/deploy_server stays
#   usable as a manual fallback, but the next source change replaces its bundle.
#   The CLIENT pack is built on devbox, in the mod repo's dev shell, from the
#   same checkout the pin names:
#     build-multiplayer --server-address 5.78.214.170
#   (the public online client: no world, no resource packs, START GAME joins
#   this box). clientGate = "pack" below admits ANY pack version at the door, so
#   a bundle rebuild no longer makes every client reinstall: a 1.0.19 or 1.0.20
#   pack keeps playing against a newer server. Two limits no knob lifts: the
#   pack itself is still required, and Fabric's registry sync disconnects a
#   client that lacks a registry entry the server has — so packs older than
#   1.0.19 cannot join at all, and a later build that ADDS registry content (an
#   item, a block, an entity, a sound) forces the reinstall after all. Publish
#   the new pack with every release anyway: an old client is admitted, it is
#   not updated.
#   Hetzner side (outside this repo): the Cloud Firewall, if one is attached,
#   must pass TCP 22, 25565 and 25600-25629 (sshd, the hub, and one port per
#   provisionable world, up to 25600 + maxProvisioned - 1). The event's rule
#   stopped at 25609 — WIDEN it, or every player whose world lands on slot 10
#   or higher hangs at the transfer. Nothing else is open: RCON and the warden
#   (127.0.0.1:25580) never leave the box.
#   Reinstall in place (no media): `sudo cala-reinstall` on the box — it carries
#   the box's own Proton PAT (/var/lib/proton-pass-cli/pat): the installer
#   fetches the GitHub token from it (cala-nix-token) and seeds it back onto the
#   reinstalled box; --token-file / --pat-file are only for a box whose PAT is
#   gone — then pick tci-cloud in the installer's TUI (cala-installer; it runs
#   disko, which asks before wiping, because this host can't set wipeAllDisks).
#   By hand that is `disko --mode destroy,format,mount --flake <ref>#tci-cloud`,
#   then `INSTALL_SKIP_DISKO=1 install-cala-m-os tci-cloud` (wiki: ISO-Installer).
#   The PAT-bearing custom ISO (build-pat-iso) remains the alternative.
#   Rebuilding FROM SCRATCH as the public fleet — the changeover from the event
#   box, and any later clean slate. Make it a REINSTALL, not a switch: a switch
#   would keep the event's registry (team entries, twin pointers), match.json
#   and practice floors under /var/lib/tci-server, none of which the public
#   fleet reads or cleans up.
#     1. Merge BOTH pull requests first — the mod's (The-Company-Inc-Nerds/
#        the-cobblemon-initiative) and this repo's — and check that the
#        flake.lock on this repo's default branch pins a cobblemon-initiative
#        rev that carries the new module. `sudo cala-reinstall` pulls the
#        DEFAULT branch of github:CalamooseLabs/cala-m-os, never a PR branch or
#        devbox's checkout: unmerged, it reinstalls the event fleet, and with a
#        stale pin the options set below (clientGate, coop.terms, selfService,
#        reclaim, …) do not exist and the evaluation fails.
#     2. If the event's memory numbers still matter, copy them off first — they
#        are the only measured sizing data there is:
#          scp hub@5.78.214.170:/var/lib/tci-server-metrics/mem.csv .
#     3. Widen the Cloud Firewall (above), then reinstall in place (above). The
#        first-install route from Rescue works too; it needs the PAT seeded
#        again (--extra-files) and gives the box new SSH host keys.
#     4. Restore nothing. The reinstall wipes the worlds, the registry and the
#        name cache, every built bundle and its build caches, the warden token
#        and the metrics CSV, and all of it regenerates: the token at
#        activation (tciWardenToken below), the bundle from the pinned source
#        (the hub waits for that first build), the registry and the worlds as
#        players arrive, the op's uuid from Mojang at the hub's first start.
#        cala-reinstall carries the Proton PAT and the SSH host keys across.
#        `nixos-version` then shows cala-2.0.0 (calamoose.version below) — the
#        public fleet; cala-1.0.0 means step 1 was skipped.
#
# Sizing — honestly. The owner asked to TRY ten worlds at once on this plan
# (8 vCPU, 32 GB) and scale back if needed, so maxActive is 10. Ten BUSY modded
# worlds do not fit in 32 GB under any setting: a world is one JVM with a 4G
# heap ceiling plus roughly 1.5 GB the heap does not count (metaspace, JIT code,
# GC bookkeeping, thread stacks, direct buffers — an ESTIMATE, neither repo
# holds a measurement), so ten full ones want about 55 GB beside the hub's 3G
# ceiling and the OS, on ~31 GB of usable RAM. What makes the attempt safe:
#   - Heaps are UNPINNED here (calamoose.tciServer.pinHeap = false, see
#     modules/tci-server): no -Xms, no AlwaysPreTouch, so a world commits what
#     it has needed rather than its ceiling, and G1PeriodicGCInterval lets an
#     idle one hand heap back. Pinned — that module's default, what tci-private
#     runs — ten 4G worlds would commit 40 GB at start. INSTANCES only: the hub
#     unit takes no jvmOpts and grows into its 3G -Xmx on demand.
#   - The warden's MEMORY GATE (warden.minFreeMemoryMB = 5120): with less than
#     5 GB of MemAvailable — about one more world — it starts no further world,
#     exactly as if maxActive were reached, and the hub queues the player until
#     a world stops. The tenth slot is only handed out while there is really
#     room for it: under real load expect the queue to form at five or six busy
#     worlds, not at ten.
#   - zram at 50 % of RAM (zstd; the module default is 25) and the 8G disk swap
#     behind it take up worlds that keep GROWING after the gate has closed.
#     That shows as GC stalls and lag in those worlds, not as a dead JVM. Only
#     past all of it does the kernel OOM killer take a process: the largest,
#     which is normally a world, and systemd restarts whatever it took
#     (Restart=on-failure) — that world's players reconnect through the hub.
#     No unit here carries a memory limit or an OOM shield; the gate is the
#     guard.
#   - An empty world stops after 5 minutes (emptyShutdownMinutes) and a dead
#     run's after about 10 s: that turnover is what hands slots and RAM on.
# CPU is the second ceiling: 8 vCPUs for up to 11 JVMs, every cold boot copies
# a 3.5 GB world and starts a modded JVM (hub.preparingCapSeconds = 900 is the
# patience for that), and a bundle rebuild may be running beside them at Nice
# 10. Decide from data, not from this paragraph: metrics.memory writes per-unit
# cgroup/RSS rows every 10 s to /var/lib/tci-server-metrics/mem.csv (never
# rotated: truncate it once the question is settled). Scaling BACK is one
# number — lower maxActive (5 or 6 is what fits in RAM at 4G a world), or raise
# warden.minFreeMemoryMB so the gate closes earlier — and a switch: the warden
# restarts with the new caps and no running world is touched. Scaling UP is a
# resize to the CCX43 (16 vCPU, 64 GB; the IPv4 stays), where ten 4G worlds
# fit in RAM and no setting in this file has to change. Disk: ~3.5 GB per
# provisioned world plus growth (30 slots ≈ 105 GB of the 240), a ~3 GB working
# copy + caches under /var/lib/tci-bundle and ~4 GB per kept bundle under
# /srv/tci (the live one + 2 older).
#
# Nobody retires worlds by hand. Players end their own (selfService): /tci-hub
# abandon deletes a solo world and frees its slot, /tci-hub coop leave takes a
# member out while the world stays with the rest, /tci-hub coop disband (the
# founder) deletes the shared world for every signatory — each behind a
# [Confirm]. And the warden reclaims what nobody uses (reclaim): every five
# minutes, among STOPPED worlds only (and never one the hub asked about in the
# last hour — a queued player's), it releases any world not started for 14
# days (idleDays), and whenever fewer than 2 of the 30 slots are free
# (keepFree) one more: first a world whose run has ended or that never started
# (once it has sat an hour), then the least recently used one that has sat idle
# 24 h. A run somebody left this evening is never taken to make room: the fleet
# reads "full" until a world qualifies. Releasing a founder's world dissolves
# the group. One journal line per release: `journalctl -u tci-server-warden`.
#
# The op. TheCalamoose is level 4 on the hub AND in every world, rewritten into
# ops.json at each unit start: an in-game /op never sticks and nobody else is
# ever op. The name is Mojang-resolved at those starts and an unresolvable one
# REFUSES the start — after a wipe the name cache is empty, so the hub's first
# start needs api.mojang.com and the exact spelling. An op passes every
# whitelist and the player cap. In the lobby, /tci-hub info prints the warden's
# view (worlds running, starting and stopped, provisioned n/30) and the queue.
# Any world can be joined straight on its port (the registry on the box maps
# players to ports: `sudo cat /var/lib/tci-server/registry.json`): on a co-op
# floor a visitor who is not on the roster is forced into spectator, but on a
# SOLO floor an op arrives as an ordinary survival player — switch to /gamemode
# spectator at once, because with deathReturnSeconds ANY death there ends the
# owner's run, and do not linger: a visitor keeps the world from spinning
# down. Root on the box adds the module's own tools: tci-server-reset
# <player|hub> (wipe + reseed), tci-server-retire <player> (delete a world and
# free its slot — what a player's own abandon / disband does), tci-bundle.
#
# Log in as `hub` with the YubiKey sk keys (users/server): the key is verified
# on the CLIENT, so the box itself needs no YubiKey. hub's login password is the
# shared admin_password from Proton Pass, as on every other host; SSH stays
# key-only (modules/openssh).
{
  lib,
  config,
  inputs,
  initialInstallMode,
  ...
}: let
  import_users = ["server"];
  machine_type = "Workstation";
  machine_uuid = "HETZNER-CLOUD";
in {
  # 2.0.0 = the PUBLIC fleet (1.0.0 was the cagelocke event fleet). The
  # installer prints it and `nixos-version` carries it, so after the changeover
  # it is the proof the box installed THIS config (header: from scratch).
  calamoose.version = "2.0.0";

  # No YubiKey on a Cloud VM, so secrets come from Proton Pass (online) instead
  # of agenix. Consumed here, both fetched at activation with the session the
  # installer-seeded PAT mints (patFile below):
  #   users/_core/secrets/default.nix -> admin_password (hub's hashedPasswordFile)
  #   modules/nix-github-token (below) -> nix-github-token (the access-tokens line
  #                                      for the private cobblemon-initiative input)
  # The warden token is not a backend item: the box generates it
  # (tciWardenToken below).
  calamoose.enableSecrets = "online";

  imports =
    [
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
        # tci-server        = the dedicated fleet (headless hardening + Aikar JVM).
        # nix-github-token  = the PAT that lets Nix fetch the PRIVATE
        #                     cobblemon-initiative flake input at eval time.
        # (cala-reinstall rides along on every physical host — _core/non-vm.nix.)
        extra_user_modules = {server = ["tci-server" "nix-github-token"];};
      })
    ]
    # tci-server, nix-github-token, proton-secrets (modules/secrets) and the
    # HETZNER-CLOUD machine's hetzner-cloud module exist only in the full config,
    # not the minimal INITIAL_INSTALL_MODE
    # pass, so their settings ride this conditional import: an unguarded
    # definition fails that pass with "option does not exist".
    ++ lib.optional (!initialInstallMode) {
      # GitHub token for the private cobblemon-initiative input. Online host: the
      # secrets facade fetches Proton item nix-github-token (vault Cala-M-OS,
      # field secret — the module defaults) to /run/proton-secrets/nix-github-token
      # and !includes it into nix.conf, so root's nix ON THE BOX fetches the input
      # (on-box nixos-rebuild, cala-reinstall). Deploying from devbox keeps
      # working: its evaluator uses its own copy of the same token. agenixFile is
      # ignored on online hosts, so it is not set.
      programs.nix-github-token.enable = true;

      # Re-mint the Proton session from the installer-seeded PAT (the `ai` /
      # `broadcast` pattern): the fs-provider session is bound to the machine-id,
      # so a session minted during the install (in nixos-anywhere's or the ISO's
      # chroot) does not match this box's own; a PAT is machine-id-independent.
      # nixos-anywhere --extra-files (header step 3), build-pat-iso and
      # cala-reinstall all land it at this path; once minted the session persists
      # (persistent root) and later boots never touch the PAT. No PAT and no
      # session: `sudo proton-secrets login` on the box. Rides this lib.optional
      # block because the proton-secrets module is absent in the minimal
      # INITIAL_INSTALL_MODE pass (a plain mkIf would still fail "option does not
      # exist" there).
      services.proton-secrets.patFile = "/var/lib/proton-pass-cli/pat";

      # ---- Hetzner Cloud networking (machines/modules/hetzner-cloud) ----------
      # Hetzner's network is routed (Layer 3): IPv4 is a /32 behind the off-subnet
      # gateway 172.31.1.1, and IPv6 is configured statically (no router
      # advertisements to rely on). Both null =
      # IPv4 over Hetzner's DHCP (systemd-networkd handles the odd gateway) and no
      # IPv6 — what a first install runs on, before the addresses are known.
      # Afterwards (header step 4): ipv4Address = "5.78.214.170" takes DHCP out
      # entirely (Hetzner notes its Layer-3 model can trip some DHCP clients) and
      # ipv6Address = "<the /64 from the Cloud Console>::1/64" (then publish AAAA).
      calamoose.hetznerCloud = {
        ipv4Address = null; # → "5.78.214.170" once the box is up
        ipv6Address = null; # e.g. "2a01:4f8:c012:3456::1/64"
      };

      # ---- Memory policy for "try ten" (header: Sizing) -----------------------
      # Ten 4G worlds cannot be heap-PINNED on 32 GB: the modules/tci-server
      # default (-Xms = -Xmx + AlwaysPreTouch) would commit 40 GB at start.
      # Unpinned, a world commits what it has needed and an idle one hands heap
      # back; the warden's memory gate (warden.minFreeMemoryMB below) then
      # decides how many really run. The option lives in modules/tci-server, so
      # it rides this block like every other fleet setting.
      calamoose.tciServer.pinHeap = false;
      # The other half: zram from the module's 25 % to half of RAM. With
      # overcommitted heaps it is the DESIGNED overflow for worlds that keep
      # growing after the gate has closed — compressed RAM first, the 8G disk
      # swap (HETZNER-CLOUD/disko.nix) behind it: lag, not a dead JVM.
      zramSwap.memoryPercent = 50;

      # ---- Warden token + deploy dir + StreamSync off (box-level glue) --------
      # The warden token stays off the secrets backend: it is a plain file the
      # module reads at RUNTIME as root (warden.py at start, the hub's preStart
      # via LoadCredential) — so generate it on the box at activation, root-only,
      # once. On this fleet only the warden and the hub hold it: plain instances
      # carry no token at all (cagelocke and the fleet-wide soul link are off, so
      # no world talks to the warden). Rotating it therefore needs no world to be
      # down: delete the file, switch again (this script writes a new one), then
      # `systemctl restart tci-server-warden tci-server-hub` — the warden reads
      # the file once at start and the hub bakes it into its marker at preStart;
      # a token file is no unit change, so the switch alone bounces neither, and
      # a hub left running keeps the old token and 401s on every warden call.
      system.activationScripts.tciWardenToken = ''
        (
          umask 077
          mkdir -p /var/lib/tci-secrets
          f=/var/lib/tci-secrets/warden-token
          if [ ! -s "$f" ]; then
            head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' >"$f"
          fi
        )
      '';

      # tci-bundle-build (root) creates /srv/tci itself; this rule only keeps
      # the manual fallback usable — scripts/deploy_server rsyncs there as the
      # ssh user (hub) — without a chown first.
      systemd.tmpfiles.rules = ["d /srv/tci 0755 hub users -"];

      # No StreamSync endpoint is reachable from this box: the overlay ingest
      # (modules/cobblemon-overlay on broadcast) is studio-LAN-only and
      # unauthenticated, while the bundle ships that LAN endpoint ENABLED (a
      # hardcoded studio-LAN <broadcast>:8082). Process env tops StreamSyncConfig's
      # precedence, so this keeps every public world from pushing its players'
      # run data at an unroutable address every few seconds. The mkIf drops it
      # once streamSync.endpointUrl is set — the module then defines "true" on
      # the same unit and the two would conflict.
      systemd.services."tci-server@".environment.STREAMSYNC_ENABLED =
        lib.mkIf (config.services.tci-server.streamSync.endpointUrl == null) "false";

      # ---- The Cobblemon Initiative PUBLIC fleet -------------------------------
      services.tci-server = {
        enable = true;
        eula = true; # accepting Mojang's EULA (required to run the server)
        # The symlink the box's own bundle build flips (bundleBuild below; also
        # what a manual scripts/deploy_server would flip). The game version IS
        # the flake input's pin: a lock bump + switch builds and links the new
        # bundle, and each unit picks it up at its next start. `sudo tci-bundle
        # use <dir>` pins a specific build instead (a rollback: later builds
        # install beside it without flipping; `tci-bundle unpin` resumes).
        bundle = "/srv/tci/bundle";
        # Build the bundle on the box from the pinned mod source (header): the
        # repo's gradle + build_mrpack pipeline into /srv/tci/bundle-<version>-
        # <source id>/, the hub gated on the first build. A lock bump + switch
        # rebuilds in the background; `sudo tci-bundle status|build|use|unpin|prune`.
        bundleBuild = {
          enable = true;
          source = inputs.cobblemon-initiative;
        };

        # Where CLIENTS reach the box: every transfer (lobby → world, world →
        # lobby) targets this address, so it MUST resolve from the players'
        # machines. The IPv4 literal until play.thecompany.inc has an A record —
        # then switch it here AND in the client pack's --server-address.
        publicHost = "5.78.214.170";

        hub.enable = true; # always-on front door (warden.enable follows hub.enable)
        # The lobby greets every joiner with clickable [Play solo] / [Co-op
        # venture] / [Status]: on an open box nobody is there to explain /tci-hub.
        hub.greeting = true;
        # hub.portal and hub.lobbyBounds stay unset: both are coordinates in the
        # bundle's reception world and have to be measured in game. Until then
        # entry is by command (the greeting's buttons) and the lobby is
        # UNCONTAINED — the hub says so at every start; the module's lobby
        # hardening (adventure mode, peaceful, 64 seats) applies regardless.

        # OPEN DOORS. Empty hub.whitelist = the hub runs with its whitelist off:
        # anyone carrying the pack walks in. Empty players = anyone in the lobby
        # may be provisioned a world. The WORLDS stay closed all the same: each
        # instance whitelists only its owner, or its co-op group, by the uuid the
        # hub authenticated — a stranger cannot walk into someone else's run.
        # ops is the one name with authority anywhere (level 4 on the hub and in
        # every world, header: The op); it is Mojang-resolved when a unit starts
        # and an unresolvable name REFUSES that start, so spell it exactly.
        players = [];
        hub.whitelist = [];
        ops = ["TheCalamoose"];

        # The door check: the pack is still required, its VERSION is not — the
        # default "exact" would turn every installed client away at each bundle
        # rebuild. Fabric's registry sync remains a second lock no knob lifts
        # (header: the CLIENT pack).
        clientGate = "pack";

        # Co-op: groups of up to four, formed in the lobby, on terms the group
        # chooses before it signs — soul link, PvP, trading & battling.
        # coop.terms.reviveSeconds (120) and .starterBalls (30) stay at the
        # module defaults: the revive window of a group WITHOUT soul link, and
        # the fourth member's Poké Balls where the three starters run out.
        coop.enable = true;
        coop.maxGroupSize = 4;
        coop.terms.enable = true;
        # NOT the group's soul link above. This switch is the FLEET-wide link
        # bus: it ties every run on the box into one shared fate and opens every
        # world's whitelist to the whole registry — never on a public fleet.
        soulLink.enable = false;

        # No operator in the loop. selfService: players end their own worlds
        # (/tci-hub abandon | coop leave | coop disband). reclaim: the warden
        # retires stopped worlds nobody has started for 14 days, and keeps 2 of
        # the 30 slots free for newcomers by releasing a world whose run has
        # ended or that never started (after an hour of quiet), else the least
        # recently used one that has sat idle 24 h (reclaim.minIdleHours, the
        # module default). Header: Nobody retires worlds by hand.
        selfService.enable = true;
        reclaim = {
          idleDays = 14;
          keepFree = 2;
        };

        # Fleet shape. maxActive = WORLDS running at once (a co-op group of four
        # is ONE): the owner's "try ten" — an allowance the memory gate below
        # rules on, not a promise (header: Sizing). maxProvisioned = worlds on
        # DISK (~3.5 GB each plus growth) and the width of the port range the
        # firewall opens: 25600-25629.
        maxActive = 10;
        maxProvisioned = 30;
        instanceDefaults = {
          # A ceiling a world grows towards, not a reservation: heaps are
          # unpinned on this box (calamoose.tciServer.pinHeap above).
          memory = "4G";
          # An empty world hands its slot and its RAM back after five minutes —
          # THE spin-down that lets ten slots serve more than ten parties.
          emptyShutdownMinutes = 5;
          # No daily 04:00 return to the lobby: the box keeps America/Denver
          # time and an open server has players in every timezone (that is
          # midday in Europe). Empty worlds stop on their own anyway.
          dailyReturnAt = null;
          # A solo death ends the run by itself: the world is condemned at once
          # and 8 s later — death screen clicked or not — the farewell and the
          # transfer back to the lobby begin; the next /tci-hub play is a fresh
          # world. (A group's run ends through its co-op session instead.)
          deathReturnSeconds = 8;
          # No max-players override: the bundle ships 4 — the co-op cap — and
          # the op bypasses the limit.
        };
        hub.memory = "3G";
        # A cold world boot (3.5 GB copy + modded JVM + the install run)
        # outlasts the 120 s default, more so with several booting at once on 8
        # vCPUs, and a timeout drops the waiting player or party.
        hub.preparingCapSeconds = 900;

        # The MEMORY GATE beside maxActive: with less than 5 GB of MemAvailable
        # — about one more world — the warden starts no further world and the
        # hub queues the player instead. What turns "try ten" into a queue
        # rather than an OOM kill (header: Sizing).
        warden.minFreeMemoryMB = 5120;
        # Warden auth, as defence in depth. The warden listens on 127.0.0.1
        # only, but every world's JVM sits on that loopback too, takes its
        # input from the open internet and holds no token: with this set, a
        # compromised one cannot drive /start or /release for somebody else's
        # world. Only the hub presents it. Generated at activation (above).
        warden.tokenFile = "/var/lib/tci-secrets/warden-token";

        openFirewall = true; # hub 25565 + worlds 25600-25629 (maxProvisioned)
        # No backups. A public run is hardcore and disposable — its own death
        # wipes it — while the tarballs would sit on this same disk (up to 30
        # worlds × 7 nightly copies of ~3.5 GB) and protect nothing against
        # losing the box; the 03:30 sweep also save-offs LIVE worlds. If that
        # ever changes, turn it on with a small backup.keep.
        backup.enable = false;
        # Per-unit cgroup/RSS CSV every 10 s — the numbers that decide whether
        # ten stays ten: /var/lib/tci-server-metrics/mem.csv
        metrics.memory.enable = true;
      };
    };

  networking.hostName = "tci-cloud";

  # ---- Remote access ------------------------------------------------------
  # The `server` profile authorizes the YubiKey (sk-ssh-ed25519) keys; sshd
  # verifies those against the public key alone, so they work on a box with no
  # YubiKey of its own. Only add a plain key here if you need to log in from a
  # machine WITHOUT the YubiKey (the account is `hub`):
  # users.users.hub.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAA... you@host"
  # ];
}
