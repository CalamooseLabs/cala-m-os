# cobblemon-overlay — stream overlay for The Cobblemon Initiative.
#
# Attached to the broadcast (stream) host only (streamer user profile). The
# game runs on battlestation; the mod's streamsync subsystem pushes JSON
# snapshots/events to this service's ingest endpoint:
#
#     http://<broadcast>:8082/ingest
#
# OBS consumes the overlay pages as local browser sources:
#
#     http://127.0.0.1:8082/overlay/party      party bar (sprites + HP)
#     http://127.0.0.1:8082/overlay/cemetery   headstone list grouped by attempt
#     http://127.0.0.1:8082/overlay/graveyard  scenic strip (?tooltips=1 cycles names)
#     http://127.0.0.1:8082/overlay/badges     badge count + level cap
#     http://127.0.0.1:8082/overlay/toasts     capture/loss/badge/whiteout popups
#
# The ingest endpoint is unauthenticated for now; the firewall restricts the
# port to battlestation only (OBS reads via loopback, which bypasses nixos-fw).
# A shared token can be added later via services.cobblemon-overlay.tokenFile
# and the secrets facade (see modules/multichat/secrets for the pattern).
{
  inputs,
  cala-m-os,
  ...
}: {
  imports = [
    inputs.antlers.nixosModules.cobblemon-overlay
  ];

  services.cobblemon-overlay = {
    enable = true;

    # Bind LAN-wide so the ingest push from battlestation (lab subnet) can
    # reach it; overlay pages are read same-box by OBS via 127.0.0.1.
    hostname = "0.0.0.0";
    port = 8082;

    openFirewall = true;
    localNetworkOnly = true;
    # Only the gaming box may reach the port from off-box. The LAN is
    # v4-static (settings.nix), so drop the module's default v6 allowances.
    localNetworkSubnets = ["${cala-m-os.ip.lab.battlestation}/32"];
    localNetworkSubnets6 = [];
  };
}
