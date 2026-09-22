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
{lib, ...}: let
  import_users = ["server"];
  machine_type = "Workstation";
  machine_uuid = "HETZNER-CLOUD";
in {
  calamoose.version = "1.0.0";

  # No Yubikey on a Cloud VM: disable agenix so activation doesn't block on a
  # hardware key. (The private cobblemon-initiative input is still fetched at
  # eval time from the DEPLOYING box's token — see nix-github-token below.)
  calamoose.enableSecrets = false;

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      # tci-server        = the dedicated fleet (headless hardening + Aikar JVM).
      # nix-github-token  = the PAT that lets Nix fetch the PRIVATE
      #                     cobblemon-initiative flake input at eval time.
      extra_user_modules = {server = ["tci-server" "nix-github-token"];};
    })
  ];

  networking.hostName = "tci-cloud";

  # PAT for the private cobblemon-initiative input. With enableSecrets = false
  # (no Yubikey on a Cloud box) the token is NOT decrypted on the box — so
  # deploy FROM a machine that already holds it (e.g. devbox) via
  # `nixos-rebuild --target-host`, whose evaluator fetches the private input.
  programs.nix-github-token = {
    enable = true;
    agenixFile = ../../modules/nix-github-token/secrets/nix-github-token.age;
  };

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
}
