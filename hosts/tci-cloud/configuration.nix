##################################
#                                #
#     TCI Cloud Server (hub)     #
#     Hetzner Cloud (US, CCX)    #
#                                #
#  Internet-facing fleet: the    #
#  hub is the front door; each   #
#  player gets a solo world, or  #
#  forms a co-op group.          #
#                                #
##################################
#
# Deploy from devbox at /etc/nixos. The cobblemon-initiative input is a PRIVATE
# repo and only root's nix on devbox holds the GitHub token for it
# (modules/nix-github-token), so every command below runs under sudo;
# --preserve-env=SSH_AUTH_SOCK lets root's ssh use your agent's YubiKey key.
#
#   First install (no custom ISO, no support ticket):
#     1. Create the server (x86 CCX, any placeholder image) with NO Volumes
#        attached, so the root disk is the only /dev/sdX (HETZNER-CLOUD/disko.nix).
#     2. Point `publicHost` below at its IPv4 (an A record; the AAAA record only
#        after step 4). Check it with `dig +short <domain> @1.1.1.1`.
#     3. Enable Rescue (linux64) with your SSH key, reset into it, and run:
#          sudo --preserve-env=SSH_AUTH_SOCK nix run github:nix-community/nixos-anywhere -- \
#            --flake .#tci-cloud --target-host root@<ipv4>
#          ssh-keygen -R <ipv4>
#        nixos-anywhere kexecs the rescue system into a NixOS installer, applies
#        this host's disko layout and installs the FULL config in one pass. The
#        box comes up on DHCP (calamoose.hetznerCloud, both addresses null).
#     4. Copy the IPv4 and the IPv6 /64 from the Cloud Console into
#        calamoose.hetznerCloud.ipv4Address / ipv6Address below, redeploy, and
#        confirm `curl -6 https://ifconfig.co` works from the box. Only then
#        publish the AAAA record.
#   Updates:
#     sudo --preserve-env=SSH_AUTH_SOCK nixos-rebuild switch --flake .#tci-cloud \
#       --target-host hub@<host> --sudo
#   Reinstall in place (no media): `sudo cala-reinstall --token-file <f>` on the
#   box — with enableSecrets = false it holds no GitHub token of its own, so hand
#   it an `access-tokens = github.com=…` line — then install-cala-m-os tci-cloud
#   in the installer (disko asks before wiping; wiki: ISO-Installer). The
#   PAT-bearing custom ISO (build-pat-iso) remains the alternative.
#
# Log in as `hub` with the YubiKey sk keys (users/server): the key is verified
# on the CLIENT, so the box itself needs no YubiKey.
{
  lib,
  initialInstallMode,
  ...
}: let
  import_users = ["server"];
  machine_type = "Workstation";
  machine_uuid = "HETZNER-CLOUD";
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
        # (cala-reinstall rides along on every physical host — _core/non-vm.nix.)
        extra_user_modules = {server = ["tci-server" "nix-github-token"];};
      })
    ]
    # tci-server, nix-github-token and the HETZNER-CLOUD machine's hetzner-cloud
    # module exist only in the full config, not the minimal INITIAL_INSTALL_MODE
    # pass, so their settings ride this conditional import: an unguarded
    # definition fails that pass with "option does not exist".
    ++ lib.optional (!initialInstallMode) {
      # PAT for the private cobblemon-initiative input. With enableSecrets = false
      # (no Yubikey on a Cloud box) the token is NOT decrypted on the box — so
      # deploy FROM a machine that already holds it (e.g. devbox) via
      # `nixos-rebuild --target-host`, whose evaluator fetches the private input.
      programs.nix-github-token = {
        enable = true;
        agenixFile = ../../modules/nix-github-token/secrets/nix-github-token.age;
      };

      # ---- Hetzner Cloud networking (machines/modules/hetzner-cloud) ----------
      # Hetzner's network is routed (Layer 3): IPv4 is a /32 behind the off-subnet
      # gateway 172.31.1.1, and IPv6 gets NO router advertisements. Both null =
      # IPv4 over Hetzner's DHCP (systemd-networkd handles the odd gateway) and no
      # IPv6 — what a first install runs on, before the addresses are known.
      # Afterwards: ipv6Address = "<the /64 from the Cloud Console>::1/64" (then
      # publish AAAA), and ipv4Address = "<the IPv4>" if DHCP is to be off
      # entirely (Hetzner notes its Layer-3 model can trip some DHCP clients).
      calamoose.hetznerCloud = {
        ipv4Address = null; # e.g. "203.0.113.10"
        ipv6Address = null; # e.g. "2a01:4f8:c012:3456::1/64"
      };

      # ---- The Cobblemon Initiative dedicated fleet (PUBLIC hub) --------------
      services.tci-server = {
        enable = true;
        eula = true; # accepting Mojang's EULA (required to run the server)
        bundle = "/srv/tci/bundle"; # `deploy_server` rsyncs here + flips the symlink

        # Where CLIENTS reach the box; instances transfer players back to it. MUST
        # be a real, client-resolvable address (DNS A/AAAA → the box's IPv4/IPv6).
        publicHost = "play.thecompany.inc"; # TODO: real DNS for the box

        hub.enable = true; # always-on front door (warden.enable follows hub.enable)
        coop.enable = true; # offer co-op groups; solo per-player worlds are the
        #                     default path — flip to false for a singleplayer-ONLY
        #                     public fleet. soulLink stays OFF: a public fleet never
        #                     shares fate or widens whitelists.

        players = []; # open auto-provisioning; hub.whitelist is the real entry gate
        hub.whitelist = []; # TODO: allowed/paid roster, or leave open
        ops = ["RoboMoose"]; # TODO: real operator name(s) (Mojang-resolved at start)

        # Sizing — MEASURE real RSS under load before packing to the RAM ceiling
        # (prior notes: an AX102/7950X3D sustains ~14-15 active instances at 6G).
        maxActive = 8; # concurrent running instances the warden allows
        maxProvisioned = 32; # worlds on disk (~3.5G each + growth)
        instanceDefaults.memory = "6G";
        hub.memory = "4G";

        openFirewall = true; # public front door: hub 25565 + game range (25600+)
        backup.enable = true;
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
