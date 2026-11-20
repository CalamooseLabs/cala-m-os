# Backend-neutral secret declarations for multichat (see
# modules/secrets/configuration.nix). multichat is enrolled only on the broadcast
# host, which runs the online (Proton Pass) backend — so these are online-only and
# carry no agenixFile. To provision each one, add an item to the "Cala-M-OS"
# Proton Pass vault titled as `itemTitle` below, with the raw value in a custom
# field named "secret" (mirrors admin_password in users/_core/secrets).
#
# multichat reads all three through LoadCredential= when it starts, so each one
# names the unit in `restartUnits`: the fetch restarts multichat when that
# secret's content changed — after a rotation in Proton Pass, or the first time
# the file appears — and leaves it alone when a fetch found nothing new.
#
# The EventSub pair is declared only once modules/multichat/ids.nix carries a
# clientId and a broadcasterId: without those the upstream module can't wire the
# secrets anyway, and declaring them early would have every fetch chase two vault
# items that don't exist yet.
{lib, ...}: let
  ids = import ../ids.nix;
  eventsub = ids.clientId != "" && ids.broadcasterId != "";
  restartUnits = ["multichat.service"];
in {
  calamoose.secrets =
    {
      # YouTube Data API v3 key — live chat polling.
      "youtube-api-key" = {
        vaultName = "Cala-M-OS";
        itemTitle = "youtube-api-key";
        field = "secret";
        inherit restartUnits;
      };
    }
    // lib.optionalAttrs eventsub {
      # Twitch application Client Secret, for minting/refreshing channel tokens.
      "twitch-client-secret" = {
        vaultName = "Cala-M-OS";
        itemTitle = "twitch-client-secret";
        field = "secret";
        inherit restartUnits;
      };

      # Seed OAuth refresh token for the broadcaster, from `multichat twitch-login`.
      # The app rotates the token in /var/lib/multichat and prefers its own copy;
      # the vault value is never written back. The unit installs this seed when
      # there is no usable token in the state directory, or when the seed itself
      # was replaced since the unit last saw it (it keeps the seed's hash beside
      # the token) — so after a re-login, updating the vault item is all it
      # takes: the next fetch (a switch, a reboot, `sudo proton-secrets refresh`)
      # restarts multichat, and that start installs the new seed. The one
      # exception is a state directory that holds a token but no hash yet (the
      # unit has not started on this seed logic before): that start only
      # records the hash, so a seed replaced before it also needs
      # /var/lib/multichat/twitch-refresh-<broadcasterId> removed.
      "twitch-refresh-${ids.channel}" = {
        vaultName = "Cala-M-OS";
        itemTitle = "twitch-refresh-${ids.channel}";
        field = "secret";
        inherit restartUnits;
      };
    };
}
