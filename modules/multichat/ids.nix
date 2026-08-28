# Non-secret Twitch identifiers for multichat's EventSub connection, kept in one
# place because both configuration.nix (which wires them) and secrets/default.nix
# (which declares the secrets they unlock) need to agree on whether they are set.
#
# Neither value is a secret — the client SECRET and the per-channel refresh token
# are, and those live in Proton Pass. Get both from the dev shell:
#
#     multichat twitch-login          # prints the broadcasterId + refresh token
#
# Until BOTH are filled in, EventSub stays off: no alerts, and the giveaway runs
# without the follow gate and without chat replies (see configuration.nix). That
# is deliberate — a half-configured EventSub would fail entries closed on air.
{
  # Client ID of the Twitch application (Developer Console → your app). Public by
  # design — it travels in every OAuth URL — so it lives here, not in Proton Pass.
  # The matching Client SECRET is a real secret and does live there.
  clientId = "pq8r7mqk8nr9j8yqf2je8z1petp1b6";

  # The Twitch login the giveaway runs on. Must be lowercase and must appear in
  # services.multichat.twitch.channels.
  channel = "thecompanyinc";

  # Numeric broadcaster user id for `channel`, from `multichat twitch-login`.
  # Public, like clientId — it appears in Helix URLs. The refresh token minted
  # alongside it is NOT public and lives in Proton Pass as
  # "twitch-refresh-thecompanyinc"; never paste it into this file.
  broadcasterId = "1477084215";
}
