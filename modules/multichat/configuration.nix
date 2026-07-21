# multichat — combined Twitch + YouTube live chat viewer.
#
# Attached to the broadcast (stream) host only (streamer user profile). The
# YouTube Data API key is sourced from the secrets facade: on hosts running a
# secrets backend (broadcast → online/Proton Pass) it is wired to
# youtube.apiKeyFile below, which the upstream module stages into the service
# via systemd LoadCredential (private tmpfs, mode 0400). Provision the value in
# Proton Pass — see modules/multichat/secrets/default.nix.
#
# When no secrets backend is active the file is left unset and the service
# starts keyless; the key can then be supplied at runtime and persisted under
# systemd's StateDirectory (/var/lib/multichat):
#
#     multichat set-youtube-key <KEY>
#
# (the `multichat` CLI is on PATH via the upstream module). Twitch needs no
# credentials and starts immediately.
{
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    inputs.multichat.nixosModules.default
    ./secrets
  ];

  # multichat reads its YouTube key file via LoadCredential at service START, so
  # on an online host — where the key arrives only after the network is up (the
  # initrd activation that would fetch it has no network; see modules/secrets) —
  # it must be bounced once the self-heal has fetched the key, or it stays keyless
  # until the next restart.
  calamoose.secretsSelfHealRestartUnits =
    lib.optionals config.calamoose._secretsEnabled ["multichat.service"];

  services.multichat = {
    enable = true;

    # LAN-reachable viewer (matches the project's settings.json) — e.g. an OBS
    # browser source or another machine on the network. The viewer is
    # unauthenticated, so keep this to a trusted LAN; tighten to "127.0.0.1" for
    # a same-box OBS overlay only. The runtime-key control endpoint is
    # loopback-only regardless of this setting.
    host = "0.0.0.0";
    port = 8081;
    openFirewall = true;

    twitch.channels = ["thecompanyinc"];
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
  };
}
