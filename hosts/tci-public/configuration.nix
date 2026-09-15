##################################
#                                #
#     TCI Public Server (hub)    #
#     Hetzner dedicated (AX)      #
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
  machine_uuid = "HETZNER-AX";
in {
  calamoose.version = "1.0.0";

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

  networking.hostName = "tci-public";

  # PAT for the private cobblemon-initiative input (agenix backend, the host
  # default). Encrypt the .age to THIS box's host key before it can self-rebuild;
  # until then, deploy FROM a box that already holds the token (e.g. devbox)
  # via `nixos-rebuild --target-host`, whose evaluator fetches the input.
  programs.nix-github-token = {
    enable = true;
    agenixFile = ../../modules/nix-github-token/secrets/nix-github-token.age;
  };

  # ---- Hetzner dedicated networking ---------------------------------------
  # Static IPv4 with an OUT-OF-SUBNET gateway (GatewayOnLink) + a static address
  # from the routed /64, via systemd-networkd. Match the NIC by MAC — the
  # interface NAME is only known once hardware-configuration.nix is generated.
  # TODO: fill in the real IPv4/prefix/gateway/MAC + /64 from Hetzner Robot, or
  # let `nixos-anywhere --generate-hardware-config` regenerate the hardware file
  # and move the match there. Placeholders below (RFC-5737 doc addresses).
  networking.networkmanager.enable = lib.mkForce false;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.MACAddress = "aa:bb:cc:dd:ee:ff"; # TODO: real NIC MAC (`ip link` in rescue)
      address = [
        "203.0.113.10/26" # TODO: real Hetzner IPv4 + prefix
        "2a01:4f8:aaaa:bbbb::1/64" # TODO: real routed /64, pick ::1
      ];
      routes = [
        {
          Gateway = "203.0.113.1"; # TODO: real IPv4 gateway (outside the subnet)
          GatewayOnLink = true;
        }
        {Gateway = "fe80::1";} # Hetzner IPv6 link-local gateway
      ];
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
