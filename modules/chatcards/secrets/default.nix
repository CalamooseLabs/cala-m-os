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
{...}: {
  # CardSight AI — card identification. Without it the service must run in mock
  # mode (see the assertion in the upstream module).
  calamoose.secrets."cardsight-api-key" = {
    vaultName = "Cala-M-OS";
    itemTitle = "cardsight-api-key";
    field = "secret";
  };

  # PriceCharting — the primary price source once set (CardSight's completed-sales
  # ladder becomes the fallback). Optional: without it CardSight pricing is used
  # on its own, but Japanese prints go unpriced.
  calamoose.secrets."pricecharting-token" = {
    vaultName = "Cala-M-OS";
    itemTitle = "pricecharting-token";
    field = "secret";
  };
}
