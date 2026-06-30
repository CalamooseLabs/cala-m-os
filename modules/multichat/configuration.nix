# multichat — combined Twitch + YouTube live chat viewer.
#
# Attached to the broadcast (stream) host only, via its `extra_user_modules`
# (see hosts/broadcast/configuration.nix). The YouTube API key is deliberately
# NOT set here: the service starts keyless and the key is supplied at runtime,
# then persisted under systemd's StateDirectory (/var/lib/multichat), surviving
# restarts/reboots. On the broadcast host run:
#
#     multichat set-youtube-key <KEY>
#
# (the `multichat` CLI is on PATH via the upstream module). Twitch needs no
# credentials and starts immediately.
{inputs, ...}: {
  imports = [
    inputs.multichat.nixosModules.default
  ];

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
    youtube.channels = [
      {channelId = "UCP3z2Yd_oe3b2Jnj3gaLsgA";}
    ];
  };
}
