##################################
#                                #
#   TCI Private Server (local)   #
#   Soul-link co-op fleet         #
#                                #
#  Internal LAN box: every        #
#  player on their OWN instance,  #
#  all soul-linked (shared fate:  #
#  damage/hunger/death propagate, #
#  spectate any run).             #
#                                #
##################################
{
  lib,
  cala-m-os,
  ...
}: let
  import_users = ["server"];
  machine_type = "Workstation";
  machine_uuid = "TCI-LOCAL";
in {
  calamoose.version = "1.0.0";

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["tci-server" "nix-github-token"];};
    })
  ];

  networking.hostName = "tci-private";

  # PAT for the private cobblemon-initiative input (see tci-cloud for the
  # host-key bootstrap note).
  programs.nix-github-token = {
    enable = true;
    agenixFile = ../../modules/nix-github-token/secrets/nix-github-token.age;
  };

  # ---- Static LAN address (lab subnet) ------------------------------------
  # Soul-link transfer targets must be client-REACHABLE, so publicHost is this
  # box's routable LAN IP — never 127.0.0.1. Keep the address stable.
  # TODO: confirm the NIC name on the actual box (placeholder enp1s0 below).
  networking.networkmanager.enable = lib.mkForce false;
  networking = {
    interfaces.enp1s0.ipv4.addresses = [
      {
        address = cala-m-os.ip.lab.tci;
        prefixLength = cala-m-os.ip.lab.prefixLength;
      }
    ];
    defaultGateway = {
      address = cala-m-os.ip.lab.gateway;
      interface = "enp1s0";
    };
    nameservers = [cala-m-os.ip.lab.gateway];
  };

  # ---- The Cobblemon Initiative dedicated fleet (PRIVATE soul-link) -------
  services.tci-server = {
    enable = true;
    eula = true;
    bundle = "/srv/tci/bundle";

    publicHost = cala-m-os.ip.lab.tci; # the box's LAN IP (clients transfer here)

    hub.enable = true; # front door + warden (warden.enable follows hub.enable)
    soulLink.enable = true; # INTERNAL shared-fate fleet. Widens every instance's
    #                         whitelist to the WHOLE registry, so provisioning
    #                         MUST be a closed roster (below). Asserts hub+warden.
    # coop.enable defaults true; a co-op group's own instance overrides soul-link
    # on that world (its members play together rather than as spectators).

    # CLOSED roster — soul-link opens every instance to the entire registry, so
    # auto-provisioning is allowlisted and the hub whitelist gates network entry.
    players = ["RoboMoose"]; # TODO: the real internal team roster
    hub.whitelist = ["RoboMoose"]; # TODO: same closed roster (network entry gate)
    ops = ["RoboMoose"]; # TODO

    maxActive = 4; # small internal fleet
    maxProvisioned = 8;
    instanceDefaults.memory = "6G";
    hub.memory = "3G";

    openFirewall = true; # trusted LAN box, no public exposure
    backup.enable = true;

    # HARDENING (optional): make the localhost warden 401 unauthenticated
    # /link/* requests. Declare a token via the secrets facade and point here —
    #   calamoose.secrets.tci-warden-token.agenixFile =
    #     ../../modules/tci-server/secrets/tci-warden-token.age;
    #   services.tci-server.warden.tokenFile =
    #     config.calamoose.secrets.tci-warden-token.path;
    # Left unset: the warden is localhost-only regardless, so on a single-box
    # fleet the token is defense-in-depth, not required.
  };
}
