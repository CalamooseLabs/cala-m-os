# multichat — combined Twitch + YouTube live chat viewer, and the giveaway engine
# that drives chat-cards (see modules/chatcards).
#
# Attached to the broadcast (stream) host only (streamer user profile). Secrets
# come from the secrets facade: on hosts running a secrets backend (broadcast →
# online/Proton Pass) each is wired to a *File option, which the upstream module
# stages into the service via systemd LoadCredential (private tmpfs, mode 0400).
# Provision the values in Proton Pass — see modules/multichat/secrets/default.nix.
#
# When no secrets backend is active the files are left unset and the service
# starts keyless; the YouTube key can then be supplied at runtime and persisted
# under systemd's StateDirectory (/var/lib/multichat):
#
#     multichat set-youtube-key <KEY>
#
# (the `multichat` CLI is on PATH via the upstream module). Twitch chat needs no
# credentials and starts immediately.
#
# ── The chat-cards loop ──────────────────────────────────────────────────────
# multichat draws a giveaway winner and POSTs to chat-cards' /api/pack to open a
# pack for them; chat-cards scans and prices the cards and POSTs each pack back
# to /api/turn-report, where it lands on that winner's turn in the ledger. Both
# services run on this box, so both calls go over loopback and neither needs a
# shared token — multichat accepts unauthenticated reports from loopback only,
# and chat-cards has no token set. Splitting them across machines means setting
# integrations.callbackToken(File) here and report.tokenFile there.
{
  inputs,
  lib,
  config,
  ...
}: let
  ids = import ./ids.nix;

  # EventSub needs the application's client id AND the channel's numeric id (plus
  # the two secrets those unlock). Until both are filled in, keep every feature
  # that depends on a broadcaster token switched OFF rather than half-configured:
  # requireFollow with no token fails entries closed, and replies would silently
  # fail to post. Fill in modules/multichat/ids.nix and they turn themselves on.
  eventsubReady =
    config.calamoose._secretsEnabled
    && ids.clientId != ""
    && ids.broadcasterId != "";

  # Total packs the campaign hands out. This is the number quoted in the terms, so
  # it is written once here and the prompt text below follows it. It is also
  # giveaway.firstN, which makes entrants #1..packCap a guaranteed-winner queue —
  # so the config and the promise agree. Note it is NOT enforced: the draw button
  # keeps working past it, pulling from the overflow pool. The cap is operator
  # discipline, not a lock.
  packCap = 1000;

  # Where the full T&C is published. multichat does NOT host a terms page — the
  # url is only substituted into the chat prompt as {terms} — so this stays empty
  # until there is a real page to point at, and the prompt carries the summary
  # instead of a dead link.
  termsUrl = "";

  termsSummary =
    "Continental US only, one entry per household, ${toString packCap} packs total. "
    + "Winners are contacted to confirm: mail, donate, pass, or destroy.";
in {
  imports = [
    inputs.multichat.nixosModules.default
    ./secrets
  ];

  # multichat reads its secret files via LoadCredential at service START, so on an
  # online host — where they arrive only after the network is up (the initrd
  # activation that would fetch them has no network; see modules/secrets) — it
  # must be bounced once the self-heal has fetched them, or it stays keyless until
  # the next restart.
  calamoose.secretsSelfHealRestartUnits =
    lib.optionals config.calamoose._secretsEnabled ["multichat.service"];

  services.multichat = {
    enable = true;

    # LAN-reachable viewer (matches the project's settings.json) — e.g. an OBS
    # browser source or another machine on the network. The viewer is
    # unauthenticated, so keep this to a trusted LAN; tighten to "127.0.0.1" for
    # a same-box OBS overlay only. The runtime-key control endpoint, /api/giveaway
    # and /api/turn-report are loopback-only regardless of this setting.
    host = "0.0.0.0";
    port = 8081;
    openFirewall = true;

    twitch = {
      channels = [ids.channel];

      # Alerts (follows, cheers, subs, raids) and the giveaway's follow gate.
      # Inert until ids.nix is filled in; see eventsubReady above.
      eventsub = lib.mkIf eventsubReady {
        clientId = ids.clientId;
        clientSecretFile = config.calamoose.secrets."twitch-client-secret".path;
        channels = [
          {
            login = ids.channel;
            broadcasterId = ids.broadcasterId;
            refreshTokenFile =
              config.calamoose.secrets."twitch-refresh-${ids.channel}".path;
          }
        ];
      };
    };

    youtube = {
      channels = [
        {channelId = "UCP3z2Yd_oe3b2Jnj3gaLsgA";}
      ];
      # Resolved secret path (/run/proton-secrets/youtube-api-key on broadcast).
      # Gated so hosts with secrets off start keyless (runtime set-youtube-key).
      apiKeyFile =
        lib.mkIf config.calamoose._secretsEnabled
        config.calamoose.secrets."youtube-api-key".path;
    };

    # The !enter giveaway. Enabled unconditionally so the pack-opening loop below
    # is live; the features that need a broadcaster token follow ids.nix.
    giveaway = {
      enable = true;
      channel = ids.channel;

      # Follow-gate entries, and confirm/deny in chat as the broadcaster. Both
      # need the channel's EventSub token: without it requireFollow fails every
      # entry closed and replies never post, so they track eventsubReady rather
      # than being hardcoded on. Re-run `multichat login` after filling in
      # ids.nix so the minted token carries the user:write:chat scope.
      requireFollow = eventsubReady;
      replies = eventsubReady;

      # Mountain Time for the compiled winners/turns report. "America/Denver",
      # not a fixed "MST" — the zone has to follow DST or half the campaign's
      # timestamps are an hour off.
      timezone = "America/Denver";

      # Entrants #1..1000 are all guaranteed a pack; a draw just picks who is
      # next. Later entrants collect in an overflow pool (followerStep is 0, so
      # no milestone draws arm on their own).
      firstN = packCap;

      # The terms gate rides eventsubReady with replies, and for the same reason:
      # the "you must accept first" prompt IS a chat reply. Switched on while
      # replies are off, an entrant who hasn't accepted is refused in silence,
      # with nothing telling them the accept command exists — worse than no gate.
      terms = {
        enable = eventsubReady;
        command = "accept"; # viewers type !accept
        version = "1"; # bump to force everyone to re-accept changed terms
        url = termsUrl;
      };

      # The winner says one of these in chat to choose what happens to their
      # pull; each choice is recorded and tallied for the campaign report.
      # Winner-only and chat-only: the handler matches the speaker's own user id
      # against the active turn, so there is no operator override anywhere — a
      # winner who stays silent leaves the turn open, and one who will not
      # cooperate cannot be dispositioned for them. Confirming out-of-band (the
      # contact step in the terms) is what actually closes most turns.
      disposition = {
        enable = true;
        mail = "mail";
        donate = "donate";
        destroy = "destroy";
        pass = "pass";
      };

      messages = {
        entered = "Thank you for entering, @{user}!";

        # Beyond firstN. The built-in default promises draws "at each follower
        # milestone", which would be a lie here: followerStep is 0, so no
        # milestone ever arms and the pool is only drawn from by hand.
        enteredPool =
          "Thank you for entering, @{user}! All ${toString packCap} packs are "
          + "spoken for — you are on the waitlist.";

        # Carries the terms itself, because termsUrl is empty and the built-in
        # prompt would otherwise render an empty "()" where the link goes.
        termsRequired =
          "@{user} type {accept} to enter. "
          + termsSummary
          + lib.optionalString (termsUrl != "") " Full terms: ${termsUrl}";
      };
    };

    # Hand each drawn winner to chat-cards, which opens a five-card pack under
    # their name. chat-cards reports the pulled cards and their value back to
    # /api/turn-report — that half is configured in modules/chatcards.
    # No token: same box, so the calls stay on loopback (see the header).
    integrations.subscribers = [
      {
        name = "chat-cards";
        adapter = "chat-cards";
        baseUrl = "http://127.0.0.1:8787";
        events = ["giveaway.turn.start"];
        packSize = 5;
      }
    ];
  };
}
