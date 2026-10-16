##################################
#                                #
#     TCI Cloud Server (hub)     #
#     Hetzner Cloud (US, CCX)    #
#                                #
#  Internet-facing fleet. Starts #
#  out as the CAGELOCKE streamer #
#  event (2v2 hardcore race);    #
#  flip fleetMode to "public"    #
#  for the open solo/co-op hub.  #
#                                #
##################################
{
  lib,
  initialInstallMode,
  ...
}: let
  import_users = ["server"];
  machine_type = "Workstation";
  machine_uuid = "HETZNER-CLOUD";

  # Which fleet this box runs:
  #   "cagelocke" — the streamer event: two 2-player teams race to a gym badge on
  #                 two team instances, refereed from the hub. Closed roster.
  #                 Design + rehearsal: docs/Cagelocke-Design.md and
  #                 docs/Cagelocke-Soak-Recipe.md (QEMU soak) in the
  #                 cobblemon-initiative repo.
  #   "public"    — the open front door: each player gets a solo world, or forms
  #                 a co-op group.
  # Flipping it on a LIVE box: the hub never restarts on a rebuild, so after the
  # switch run `systemctl restart tci-server-hub` (else it keeps its old marker —
  # going to cagelocke, the token-guarded warden then 401s it). Leave cagelocke
  # only after `/tci-hub cage reset` with both team floors stopped.
  fleetMode = "cagelocke";

  # ---- Cagelocke roster ---------------------------------------------------
  # Exact Minecraft Java names. The hub resolves every name here against Mojang
  # at start; the team floors resolve only the referee and casters (streamers
  # reach them by the uuid the hub captured at login). An unresolvable name
  # refuses that start. After changing the roster on a live box, run
  # `systemctl restart tci-server-hub` — the hub never restarts on a rebuild.
  streamers = []; # TODO: the four streamers (two teams of two). Until filled,
  #                 only the referee and casters get past the hub whitelist, and
  #                 nobody may provision (see players below).
  referee = "RoboMoose"; # TODO: the referee — the ONLY op, never a streamer
  casters = []; # in-world casters (spectate both team floors), if any

  # Root-only, generated on the box (see tci-warden-token below). A string, not a
  # path literal, so it never lands in the Nix store.
  wardenTokenFile = "/var/lib/tci-secrets/warden-token";
in {
  calamoose.version = "1.0.0";

  # No Yubikey on a Cloud VM: disable agenix so activation doesn't block on a
  # hardware key. (The private cobblemon-initiative input is still fetched at
  # eval time from the DEPLOYING box's token — see nix-github-token below.)
  calamoose.enableSecrets = false;

  imports =
    [
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
        # tci-server        = the dedicated fleet (headless hardening + Aikar JVM).
        # nix-github-token  = the PAT that lets Nix fetch the PRIVATE
        #                     cobblemon-initiative flake input at eval time.
        # cala-reinstall    = `sudo cala-reinstall` turns the box back into the
        #                     installer in place (kexec), no custom ISO needed.
        extra_user_modules = {server = ["tci-server" "nix-github-token" "cala-reinstall"];};
      })
    ]
    # tci-server and nix-github-token exist only in the full config, not the minimal
    # INITIAL_INSTALL_MODE pass, so their settings ride this conditional import:
    # an unguarded definition fails that pass with "option does not exist".
    ++ lib.optional (!initialInstallMode) {
      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion = lib.elem fleetMode ["cagelocke" "public"];
              message = "tci-cloud: fleetMode must be \"cagelocke\" or \"public\" (got \"${fleetMode}\").";
            }
          ];

          # PAT for the private cobblemon-initiative input. With enableSecrets = false
          # (no Yubikey on a Cloud box) the token is NOT decrypted on the box — so
          # deploy FROM a machine that already holds it (e.g. devbox) via
          # `nixos-rebuild --target-host`, whose evaluator fetches the private input.
          programs.nix-github-token = {
            enable = true;
            agenixFile = ../../modules/nix-github-token/secrets/nix-github-token.age;
          };

          # ---- The Cobblemon Initiative dedicated fleet (both modes) ------------
          services.tci-server = {
            enable = true;
            eula = true; # accepting Mojang's EULA (required to run the server)
            # `deploy_server` rsyncs here + flips the symlink. TODO(event): freeze it —
            # once the event build is deployed, point this at the versioned dir (/srv/tci/bundle-cobblemon-initiative-<ver>)
            # so a mid-event deploy can't reseed a wiped team on a newer build that
            # the streamers' client packs no longer match.
            bundle = "/srv/tci/bundle";

            # Where CLIENTS reach the box; instances transfer players back to it. MUST
            # be a real, client-resolvable address (DNS A/AAAA → the box's IPv4/IPv6),
            # and the same name the client pack is built with (--server-address).
            publicHost = "play.thecompany.inc"; # TODO: real DNS for the box

            hub.enable = true; # always-on front door (warden.enable follows hub.enable)
            coop.enable = true; # co-op groups — and cagelocke's teams ARE co-op groups.
            #                     soulLink stays OFF: a public fleet never shares fate,
            #                     and cagelocke asserts it off.

            # Sizing — MEASURE real RSS under load before packing to the RAM ceiling.
            # Instance heaps are pinned (-Xms = -Xmx, AlwaysPreTouch), so each running
            # instance holds its full heap from boot.
            instanceDefaults.memory = "6G";
            hub.memory = "4G";

            openFirewall = true; # public front door: hub 25565 + game range (25600+)
          };
        }

        # ---- CAGELOCKE: the streamer event ------------------------------------
        (lib.mkIf (fleetMode == "cagelocke") {
          assertions = [
            {
              assertion = !(lib.elem (lib.toLower referee) (map lib.toLower streamers));
              message = "tci-cloud: the cagelocke referee (${referee}) is also listed as a streamer — ops bypass the race's containment, so the referee must be a separate account.";
            }
          ];
          warnings = lib.optional (streamers == []) "tci-cloud: the cagelocke roster (streamers) is empty — nobody can provision or form a team until it is filled in.";

          services.tci-server = {
            cagelocke = {
              enable = true; # needs hub + warden + coop, and soulLink off (asserted)
              targetBadge = 3; # the badge count that ends the race (1..10)
              # Whitelisted on BOTH team floors (on top of the registry). Not added to
              # hub.whitelist automatically — that's done below.
              guests = [referee] ++ casters;
            };
            coop.maxGroupSize = 2; # the warden only files 2-player teams

            # CLOSED roster. Team floors whitelist the WHOLE registry, so only the
            # streamers may provision, and the hub whitelist is everyone's way in.
            # An EMPTY players list means OPEN provisioning, so until the roster is
            # filled hold it closed with a name no Java account can have (a hyphen) —
            # otherwise the referee could mint a stray world that never boots but
            # holds a slot and is whitelisted on both floors.
            players =
              if streamers == []
              then ["-roster-unset-"]
              else streamers;
            hub.whitelist = streamers ++ [referee] ++ casters;
            ops = [referee]; # referee commands (/tci-hub cage create|start|reset,
            #                  /cage admin, /cage finale) need op. Never a streamer.

            # Two team floors + the hub: ~2×(6G heap + overhead) + 4G hub ≈ 24 GB
            # resident, so a 32 GB box (e.g. CCX33) is the floor.
            maxActive = 2; # only the two team leaders' instances ever run
            maxProvisioned = 4; # two teams + slack for a stray or a re-formed group
            hub.preparingCapSeconds = 600; # a cold team-world boot overruns the 120 s default
            instanceDefaults = {
              emptyShutdownMinutes = 0; # never halt a floor while its team is out hunting
              dailyReturnAt = null; # no 04:00 bounce to the hub mid-race
              # The bundle ships 4; a floor holds its 2 members + up to 2 rivals
              # (hunter + spectating partner, or the losing team at the finale) + the
              # referee (an op bypasses the cap but still takes a slot), plus casters.
              # Raise it for more than 3 casters.
              serverProperties."max-players" = 8;
            };

            # Team worlds are disposable (a wipe deletes them), and the nightly
            # save-off/tar sweep would hitch a live floor.
            backup.enable = false;

            # Required, not just hardening: only with a token does an instance that
            # crashes mid-wipe report the reset back to the warden on restart
            # (POST /cage/reset-consumed); without it the match record goes stale.
            warden.tokenFile = wardenTokenFile;
          };

          # The warden token: nothing off the box ever needs it (the localhost
          # warden, the hub and the instances), and with no secrets backend here,
          # mint it on first boot and keep it. The hub and instances read it via
          # LoadCredential.
          systemd.services.tci-warden-token = {
            description = "Generate the TCI warden bearer token";
            # The hub and warden Require this unit, so a rebuild that restarted it
            # would bounce the lobby mid-race (the hub itself never restarts on a
            # rebuild). The token is minted once and kept, so never re-run it.
            restartIfChanged = false;
            before = ["tci-server-warden.service" "tci-server-hub.service"];
            requiredBy = ["tci-server-warden.service" "tci-server-hub.service"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              UMask = "0077";
            };
            script = ''
              if [ ! -s ${wardenTokenFile} ]; then
                mkdir -p "$(dirname ${wardenTokenFile})"
                head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > ${wardenTokenFile}.tmp
                mv ${wardenTokenFile}.tmp ${wardenTokenFile}
              fi
            '';
          };

          # The bundle ships StreamSync ON, aimed at a LAN overlay Hetzner can't reach.
          # Off until the event overlay exists — then set
          # services.tci-server.streamSync.{endpointUrl,tokenFile}, which turns it back
          # on (the module's "true" outranks this default).
          systemd.services."tci-server@".environment.STREAMSYNC_ENABLED = lib.mkDefault "false";
        })

        # ---- PUBLIC: the open solo / co-op front door -------------------------
        (lib.mkIf (fleetMode == "public") {
          services.tci-server = {
            # Solo per-player worlds are the default path; coop.enable (above) also
            # offers co-op groups — flip it to false for a singleplayer-ONLY fleet.
            players = []; # open auto-provisioning; hub.whitelist is the real entry gate
            hub.whitelist = []; # TODO: allowed/paid roster, or leave open
            ops = ["RoboMoose"]; # TODO: real operator name(s) (Mojang-resolved at start)

            # Prior notes: an AX102/7950X3D sustains ~14-15 active instances at 6G.
            maxActive = 8; # concurrent running instances the warden allows
            maxProvisioned = 32; # worlds on disk (~3.5G each + growth)

            backup.enable = true;
          };
        })
      ];
    };

  networking.hostName = "tci-cloud";

  # ---- Remote access ------------------------------------------------------
  # A Cloud box has NO Yubikey, but the `server` profile authorizes only Yubikey
  # (sk-ssh-ed25519) keys — so add a PLAIN key you hold or you are locked out
  # after the first reboot (only the web VNC console would remain).
  # TODO: drop in your real public key and uncomment (the login account is `hub`):
  # users.users.hub.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAA... you@host"
  # ];

  # ---- Hetzner Cloud networking -------------------------------------------
  # Cloud instances get their public IPv4 via DHCP and IPv6 via router
  # advertisements — no static addressing (unlike Robot/AX bare metal). Match
  # the primary NIC by name glob so we don't depend on its exact name.
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "en*";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
