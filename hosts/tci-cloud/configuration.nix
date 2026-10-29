##################################
#                                #
#  TCI Cloud Server (cagelocke)  #
#  Hetzner Cloud CCX33 (US)      #
#  5.78.214.170                  #
#                                #
#  The Cobblemon Initiative      #
#  EVENT fleet: hub + warden +   #
#  two 2-player team worlds +    #
#  practice floors. TEST box:    #
#  sized for the CCX33 (8 vCPU,  #
#  32 GB, 240 GB); hot standby   #
#  waits for a 64 GB plan.       #
#                                #
##################################
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
#        resolve for the test. When play.thecompany.inc gets an A record pointing
#        at it (`dig +short play.thecompany.inc @1.1.1.1`), switch publicHost AND
#        the client pack's --server-address to the name; the AAAA record only
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
#        real box's — commit it. Never rerun nixos-anywhere on an installed box:
#        it wipes the disk; updates go through nixos-rebuild below.)
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
#   The game bundle: the box builds it ITSELF (services.tci-server.bundleBuild,
#   the mod module's BUNDLE BUILD) from the flake input that pins the mod — the
#   repo's own `gradle build` + build_mrpack.py --profile server pipeline runs on
#   the box into /srv/tci/bundle-<version>-<source id>/ and flips /srv/tci/bundle.
#   A fresh box's hub waits for the first build (tci-bundle-ready), so a new
#   install needs no deploy step, and the bundle needs no GitHub fetch of its
#   own (the ~2 GB source travels inside the system closure). 1.0.18's
#   cagelocke/standby/practice Java gets its FIRST real compile there: watch it.
#     ssh hub@5.78.214.170 'journalctl -fu tci-bundle-build'   # the first build also
#                                                   # downloads Maven/Modrinth/Fabric deps
#     ssh hub@5.78.214.170 sudo tci-bundle status   # pinned source, live link, pin, bundles
#   New game version = move the pin and redeploy: on devbox
#     sudo nix flake update cobblemon-initiative && <an Updates command above>
#   The switch returns at once and the box rebuilds in the background; the hub
#   and running floors keep their bundle until restarted:
#     ssh hub@5.78.214.170 sudo systemctl restart tci-server-hub   # when the lobby is quiet
#   (`sudo tci-bundle build --restart-hub` does both by hand; `tci-bundle use
#   <dir>` pins the link to a kept bundle — the EVENT freeze — and `tci-bundle
#   unpin` follows new builds again.) Only a switch issued while the FIRST build
#   is still running waits for it, through the hub. The CLIENT pack is still
#   built on devbox from the same checkout, with --server-address 5.78.214.170
#   (the exact-version gatekeeper: every bundle rebuild = every client
#   reinstalls); scripts/deploy_server stays usable as a manual fallback, but
#   the next source change replaces its bundle.
#   Hetzner side (outside this repo): the Cloud Firewall, if one is attached,
#   must pass TCP 22, 25565 and 25600-25609 (hub, team range, practice range).
#   Reinstall in place (no media): `sudo cala-reinstall` on the box — it carries
#   the box's own Proton PAT (/var/lib/proton-pass-cli/pat): the installer
#   fetches the GitHub token from it (cala-nix-token) and seeds it back onto the
#   reinstalled box; --token-file / --pat-file are only for a box whose PAT is
#   gone — then pick tci-cloud in the installer's TUI (cala-installer; it runs
#   disko, which asks before wiping, because this host can't set wipeAllDisks).
#   By hand that is `disko --mode destroy,format,mount --flake <ref>#tci-cloud`,
#   then `INSTALL_SKIP_DISKO=1 install-cala-m-os tci-cloud` (wiki: ISO-Installer).
#   The PAT-bearing custom ISO (build-pat-iso) remains the alternative.
#
# Sizing on the CCX33 (8 vCPU, 32 GB): two team floors 6G each, pre-touched at
# start (the Aikar -Xms pin in modules/tci-server — INSTANCES only: the hub unit
# takes no jvmOpts) = 12 GB committed up front, plus the hub's 4G -Xmx ceiling it
# grows into = 16 GB of heap at most, ~20-22 GB with JVM overhead; one practice
# floor at a time (6G, pinned like a team floor) beside them. Hot standby (a
# second, pre-booted JVM per team; on a standby fleet EVERY team world runs
# cagelocke.standby.jvmOpts, heap pin dropped, so the -Xmx sum does not size it)
# and practice.maxActive 2 need the 64 GB CCX43. metrics.memory below writes the
# per-unit RSS CSV (/var/lib/tci-server-metrics/mem.csv): size the upgrade from
# it, not from -Xmx (Cagelocke-Design §5.8 / Q21). Disk: the bundle build keeps
# a ~3 GB working copy + caches under /var/lib/tci-bundle and ~4 GB per kept
# bundle under /srv/tci (the live one + 2 older), beside the ~3.5 GB team worlds.
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
  calamoose.version = "1.0.0";

  # No YubiKey on a Cloud VM, so secrets come from Proton Pass (online) instead
  # of agenix. Consumed here, both fetched at activation with the session the
  # installer-seeded PAT mints (patFile below):
  #   users/_core/secrets/default.nix -> admin_password (hub's hashedPasswordFile)
  #   modules/nix-github-token (below) -> nix-github-token (the access-tokens line
  #                                      for the private cobblemon-initiative input)
  # The warden/practice event tokens are not backend items: the box generates
  # them (tciEventTokens below).
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

      # ---- Event tokens + deploy dir + StreamSync off (box-level glue) -------
      # The warden/practice tokens stay off the secrets backend: they are plain
      # files the module reads at RUNTIME as root (warden.py at
      # start, the hub/instance preStarts via LoadCredential, tci-server-practice)
      # — so generate them on the box at activation, root-only, once. Rotate ONLY
      # between races (no tci-server@ / tci-server-practice@ JVM up): delete the
      # file, switch again, then restart EVERY unit that holds it — the warden
      # reads both files once at start, and the hub, each tci-server@<team> floor
      # (warden-token) and each tci-server-practice@<Owner>.p floor
      # (practice-token) bake theirs into their marker at preStart; the units are
      # restartIfChanged = false, so a switch bounces none of them, and a floor
      # left running keeps the old token and 401s on every /cage/* call.
      system.activationScripts.tciEventTokens = ''
        (
          umask 077
          mkdir -p /var/lib/tci-secrets
          for t in warden-token practice-token; do
            f=/var/lib/tci-secrets/$t
            if [ ! -s "$f" ]; then
              head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' >"$f"
            fi
          done
        )
      '';

      # tci-bundle-build (root) creates /srv/tci itself; this rule only keeps
      # the manual fallback usable — scripts/deploy_server rsyncs there as the
      # ssh user (hub) — without a chown first.
      systemd.tmpfiles.rules = ["d /srv/tci 0755 hub users -"];

      # No StreamSync endpoint is reachable from this box yet: the overlay ingest
      # (modules/cobblemon-overlay on broadcast) is studio-LAN-only and
      # unauthenticated, while the bundle ships that LAN endpoint ENABLED (a
      # hardcoded studio-LAN <broadcast>:8082). Process env tops StreamSyncConfig's
      # precedence, so this keeps the team floors from pushing into the void. The
      # mkIf drops it once streamSync.endpointUrl is set — the module then defines
      # "true" on the same unit and the two would conflict.
      systemd.services."tci-server@".environment.STREAMSYNC_ENABLED =
        lib.mkIf (config.services.tci-server.streamSync.endpointUrl == null) "false";

      # ---- The Cobblemon Initiative cagelocke fleet (TEST deployment) ----------
      services.tci-server = {
        enable = true;
        eula = true; # accepting Mojang's EULA (required to run the server)
        # The symlink the box's own bundle build flips (bundleBuild below; also
        # what a manual scripts/deploy_server would flip). The EVENT pin is the
        # flake input: do not `nix flake update cobblemon-initiative` during the
        # freeze, and `sudo tci-bundle use <dir>` pins a specific build (later
        # builds install beside it without flipping; `tci-bundle unpin` resumes)
        # — a newer bundle would otherwise reseed a wiped team on a version the
        # hub and the clients do not run, and the exact-version gate locks it out.
        bundle = "/srv/tci/bundle";
        # Build the bundle on the box from the pinned mod source (header): the
        # repo's gradle + build_mrpack pipeline into /srv/tci/bundle-<version>-
        # <source id>/, the hub gated on the first build. A lock bump + switch
        # rebuilds in the background; `sudo tci-bundle status|build|use|unpin|prune`.
        bundleBuild = {
          enable = true;
          source = inputs.cobblemon-initiative;
        };

        # Where CLIENTS reach the box: every transfer (hub → floor, floor → hub,
        # the hunt, spectate) targets this address, so it MUST resolve from the
        # players' machines. The IPv4 literal until play.thecompany.inc has an A
        # record — then switch it here AND in the client pack's --server-address.
        publicHost = "5.78.214.170";

        hub.enable = true; # always-on front door (warden.enable follows hub.enable)
        coop.enable = true; # teams ARE co-op groups (cagelocke asserts it)
        coop.maxGroupSize = 2; # 2v2: a team is exactly two
        soulLink.enable = false; # the inverse of every cagelocke rule (asserted)

        # ROSTER — TODO before anyone but the testers connects. hub.whitelist,
        # ops and cagelocke.guests are Mojang-resolved when their unit starts: an
        # unresolvable name REFUSES that start, so spell them exactly and boot
        # once online. `players` is NOT resolved — the warden matches it
        # case-insensitively, so a typo there 403s that streamer later, at
        # /tci-hub coop sign | play | practice start, never at boot.
        #   hub.whitelist    = the four streamers + casters + referee;
        #   players          = the four streamers (who may hold a team world);
        #   ops              = the referee ONLY — streamers must never be ops;
        #   cagelocke.guests = the casters (+ referee) allowed onto a team floor.
        # Empty whitelist/players = anyone who finds the IP may form a team AND,
        # with practice on, open a practice floor (/tci-hub practice start is
        # perm 0; the warden's only gate is `players`, empty = open): one 6G JVM
        # at a time (practice.maxActive) and up to 4 × ~3.5 GB seeded worlds on
        # disk (practice.maxWorlds). Fill `players` before the IP circulates;
        # `/tci-hub practice close` (referee) latches it shut meanwhile.
        players = [];
        hub.whitelist = [];
        ops = ["TheCalamoose"]; # TODO: the referee's real Mojang name

        # Fleet shape for a race: two team worlds plus slack for retire/re-form.
        # Firewall exposure follows maxProvisioned (team ports 25600-25605).
        maxActive = 2;
        maxProvisioned = 6;
        instanceDefaults = {
          memory = "6G";
          emptyShutdownMinutes = 0; # a team floor never spins down mid-race
          dailyReturnAt = null; # no 04:00 return to the hub during an event
          # Two members + a hunter + casters on one floor (the bundle ships 4).
          serverProperties."max-players" = 8;
        };
        hub.memory = "4G";
        # A cold team-world boot (3.5 GB copy + modded JVM + the install run)
        # outlasts the 120 s default, and a timeout drops the armed party.
        hub.preparingCapSeconds = 900;

        # Warden auth: every /cage/* and /practice/* request carries the bearer
        # token; without it the crash-in-wipe reset backstop is never emitted and
        # practice floors cannot be enabled. Generated at activation (above).
        warden.tokenFile = "/var/lib/tci-secrets/warden-token";

        cagelocke = {
          enable = true;
          # targetBadge 3 (owner ruling 1), reviveSeconds 120, huntSeconds,
          # hunterLives and mobWheel stay at the module's canon defaults.
          guests = []; # TODO: the casters' Mojang names
          # Hot standby (a pre-booted spare JVM per team) does not fit 32 GB —
          # turn it on after the plan upgrade, sized from the memory CSV.
          standby.enable = false;
          # Practice floors (1.0.18): streamers rehearse on their own floors in
          # the days before. ONE at a time on this plan (6G pinned, beside the
          # hub and any team floor still up); raise maxActive with the box.
          # Event morning: `sudo tci-server-practice sweep`, then /tci-hub cage create
          # (which refuses while any practice JVM is on the box).
          practice = {
            enable = true;
            tokenFile = "/var/lib/tci-secrets/practice-token";
            maxActive = 1;
            # maxWorlds 4; memory = instanceDefaults.memory — never lower it
            # alone (the Aikar -Xms pin would exceed -Xmx); ports 25606-25609.
          };
        };

        openFirewall = true; # hub 25565 + team 25600-25605 + practice 25606-25609
        # The design's event config: the 03:30 sweep save-offs LIVE team worlds,
        # and test worlds need no backups. Decide before the real event.
        backup.enable = false;
        # Per-unit cgroup/RSS CSV every 10 s — the numbers to size the next plan
        # (and standby) from: /var/lib/tci-server-metrics/mem.csv
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
