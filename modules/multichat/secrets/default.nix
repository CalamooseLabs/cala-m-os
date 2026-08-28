# Backend-neutral secret declarations for multichat (see
# modules/secrets/configuration.nix). multichat is enrolled only on the broadcast
# host, which runs the online (Proton Pass) backend — so these are online-only and
# carry no agenixFile. To provision each one, add an item to the "Cala-M-OS"
# Proton Pass vault titled as `itemTitle` below, with the raw value in a custom
# field named "secret" (mirrors admin_password in users/_core/secrets).
#
# The EventSub pair is declared only once modules/multichat/ids.nix carries a
# clientId and a broadcasterId: without those the upstream module can't wire the
# secrets anyway, and declaring them early would have activation chase two vault
# items that don't exist yet.
{lib, ...}: let
  ids = import ../ids.nix;
  eventsub = ids.clientId != "" && ids.broadcasterId != "";
in {
  calamoose.secrets =
    {
      # YouTube Data API v3 key — live chat polling.
      "youtube-api-key" = {
        vaultName = "Cala-M-OS";
        itemTitle = "youtube-api-key";
        field = "secret";
      };
    }
    // lib.optionalAttrs eventsub {
      # Twitch application Client Secret, for minting/refreshing channel tokens.
      "twitch-client-secret" = {
        vaultName = "Cala-M-OS";
        itemTitle = "twitch-client-secret";
        field = "secret";
      };

      # Seed OAuth refresh token for the broadcaster, from `multichat twitch-login`.
      # Installed into /var/lib/multichat on first start only — the app rotates it
      # from there afterwards and the vault copy is never written back, so a
      # re-provisioned value takes effect only if that state file is removed.
      "twitch-refresh-${ids.channel}" = {
        vaultName = "Cala-M-OS";
        itemTitle = "twitch-refresh-${ids.channel}";
        field = "secret";
      };
    };
}
