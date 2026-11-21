# Backend-neutral secret declarations for chat-cards (see
# modules/secrets/configuration.nix). chat-cards is enrolled only on the
# broadcast host, which runs the online (Proton Pass) backend — so these are
# online-only and carry no agenixFile. To provision each one, add an item to the
# "Cala-M-OS" Proton Pass vault titled as `itemTitle` below, with the raw value
# in a custom field named "secret" (mirrors admin_password in users/_core/secrets).
#
# The attribute NAME is what consumers reference as
# `config.calamoose.secrets."<name>".path`; `itemTitle` is what the vault item is
# called. They differ for the PriceCharting token because the vault item was
# created under the vendor's own wording.
#
# chat-cards reads both through LoadCredential= when it starts, so each one names
# the unit in `restartUnits`: the fetch restarts chat-cards when that key's
# content changed — after a rotation in Proton Pass, or the first time the file
# appears — and leaves it alone when a fetch found nothing new.
{...}: let
  restartUnits = ["chat-cards.service"];
in {
  # CardSight AI — card identification. Without it the service must run in mock
  # mode (see the assertion in the upstream module).
  calamoose.secrets."cardsight-api-key" = {
    vaultName = "Cala-M-OS";
    itemTitle = "cardsight-api-key";
    field = "secret";
    inherit restartUnits;
  };

  # PriceCharting — the primary price source once set (CardSight's completed-sales
  # ladder becomes the fallback). Optional for the app: without it CardSight
  # pricing is used on its own, but Japanese prints go unpriced. Not `optional`
  # for the fetch, though: modules/chatcards hands the file to the unit through
  # LoadCredential, so the unit cannot start while it is missing.
  calamoose.secrets."pricecharting-token" = {
    vaultName = "Cala-M-OS";
    itemTitle = "pricecharting-token";
    field = "secret";
    inherit restartUnits;
  };
}
