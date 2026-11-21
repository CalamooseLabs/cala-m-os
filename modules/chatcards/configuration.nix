# chat-cards — the pack-opening scanner and OBS overlay, and the other half of
# multichat's giveaway loop (see modules/multichat).
#
# Attached to the broadcast (stream) host only (streamer user profile). A producer
# scans each revealed card from a phone at /scan; /overlay is the page an OBS
# browser source shows. Both API keys come from the secrets facade — on hosts
# running a backend (broadcast → online/Proton Pass) they are wired to the *File
# options, which the upstream module stages via systemd LoadCredential.
# Provision them in Proton Pass — see modules/chatcards/secrets/default.nix.
#
# With LoadCredential the unit cannot start until those files exist, and nothing
# here orders it onto the secrets fetch: each key names chat-cards.service in its
# `restartUnits` (./secrets), so the fetch restarts it when a key changed or
# first appears — also when it has landed in `failed` by then — and until then
# the unit retries on its own restart policy. On broadcast the files are
# restored from the sealed cache before any service starts, so the unit normally
# finds them on its first start, with or without the internet. modules/secrets
# has the reasoning.
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

  services.chat-cards = {
    enable = true;

    # LAN-reachable so the producer's phone can hit /scan and an OBS on the
    # LAN can load /overlay; one on this box reads it over loopback.
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
