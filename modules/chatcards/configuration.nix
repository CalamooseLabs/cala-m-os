# chat-cards — the pack-opening scanner and OBS overlay, and the other half of
# multichat's giveaway loop (see modules/multichat).
#
# Attached to the broadcast (stream) host only (streamer user profile). A producer
# scans each revealed card from a phone at /scan; OBS reads /overlay over
# loopback. Both API keys come from the secrets facade — on hosts running a
# backend (broadcast → online/Proton Pass) they are wired to the *File options,
# which the upstream module stages via systemd LoadCredential. Provision them in
# Proton Pass — see modules/chatcards/secrets/default.nix.
#
# With no secrets backend there is no CardSight key, so the service runs in mock
# mode (canned identify/pricing, nothing billed) rather than tripping the module's
# assertion — which also makes the whole giveaway→pack→ledger loop rehearsable
# offline.
{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    inputs.chatcards.nixosModules.default
    ./secrets
  ];

  # chat-cards reads its key files via LoadCredential at service START, so on an
  # online host — where they arrive only after the network is up (the initrd
  # activation that would fetch them has no network; see modules/secrets) — it
  # must be bounced once the self-heal has fetched them, or it stays keyless (and
  # therefore failing every scan) until the next restart.
  calamoose.secretsSelfHealRestartUnits =
    lib.optionals config.calamoose._secretsEnabled ["chat-cards.service"];

  services.chat-cards = {
    enable = true;

    # LAN-reachable so the producer's phone can hit /scan; OBS reads /overlay
    # over loopback on the same box.
    address = "0.0.0.0";
    port = 8787;
    openFirewall = true;

    # No backend → no key → run canned rather than failing the assertion.
    mock = !config.calamoose._secretsEnabled;

    apiKeyFile =
      lib.mkIf config.calamoose._secretsEnabled
      config.calamoose.secrets."cardsight-api-key".path;

    pricechartingTokenFile =
      lib.mkIf config.calamoose._secretsEnabled
      config.calamoose.secrets."pricecharting-token".path;

    segment = "pokemon";

    # Close multichat's giveaway loop: multichat opens a pack here for each drawn
    # winner (its integrations subscriber points at port 8787), and every pack is
    # POSTed back as its cards are scanned and priced, so the per-winner ledger on
    # /giveaway carries what was actually pulled and what it was worth.
    #
    # Loopback, so no token: multichat accepts unauthenticated reports from
    # loopback and requires integrations.callbackToken only from anywhere else.
    # Reporting is fire-and-forget — a multichat that is down or restarting never
    # interrupts a reveal, and the next update reconciles what was missed.
    report.url = "http://127.0.0.1:8081/api/turn-report";
  };
}
