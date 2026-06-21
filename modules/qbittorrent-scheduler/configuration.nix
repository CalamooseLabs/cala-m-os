# Scheduled qBittorrent alternative speed limits.
#
# qBittorrent's "scheduler" is not a systemd service — it is a built-in feature
# configured via qBittorrent.conf. This module is a thin, reusable policy layer
# over the knobs the `qbittorrent` module already exposes: during the configured
# window it makes qBittorrent fall back to the (lower) alternative rate limits,
# so bulk peer traffic backs off during prime streaming hours and the *arr
# import copies to the NAS are less likely to compete with Plex reads.
#
# Import it anywhere qbittorrent-vpn runs and leave it off (the default); flip
# `services.qbittorrent-scheduler.enable = true` to activate. Times are in the
# host's local timezone.
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.qbittorrent-scheduler;
in {
  options.services.qbittorrent-scheduler = {
    enable = mkEnableOption "scheduled qBittorrent alternative (throttled) speed limits";

    from = mkOption {
      type = types.str;
      default = "17:00";
      example = "18:00";
      description = "Start of the throttled window (HH:MM, host local time). Within this window qBittorrent uses the alternative limits below.";
    };

    to = mkOption {
      type = types.str;
      default = "23:00";
      example = "23:30";
      description = "End of the throttled window (HH:MM, host local time).";
    };

    download = mkOption {
      type = types.nullOr types.int;
      default = 10240; # 10 MB/s
      description = "Alternative download limit in KB/s applied during the window (null for unlimited).";
    };

    upload = mkOption {
      type = types.nullOr types.int;
      default = 5120; # 5 MB/s
      description = "Alternative upload limit in KB/s applied during the window (null for unlimited).";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.qbittorrent-vpn.enable;
        message = "services.qbittorrent-scheduler requires services.qbittorrent-vpn to be enabled.";
      }
    ];

    services.qbittorrent-vpn.speedLimits = {
      enableScheduler = true;
      scheduleFrom = cfg.from;
      scheduleTo = cfg.to;
      alternativeDownload = cfg.download;
      alternativeUpload = cfg.upload;
    };
  };
}
