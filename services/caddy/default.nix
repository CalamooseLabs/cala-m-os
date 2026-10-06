{
  config,
  lib,
  ...
}: let
  cfg = config.services.cala-caddy;
in {
  options.services.cala-caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy with Cala-M-OS TLS defaults";

    reverseProxies = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = lib.literalExpression ''
        {
          "app.example.com" = "localhost:8080";
        }
      '';
      description = "Map of virtual-host domains to their reverse-proxy upstream targets.";
    };

    tlsCert = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/acme/cert.pem";
      description = "Path to the TLS certificate served for every virtual host.";
    };

    tlsKey = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/acme/key.pem";
      description = "Path to the TLS private key served for every virtual host.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Reverse Proxy
    services.caddy = {
      enable = true;

      virtualHosts =
        builtins.mapAttrs (_domain: target: {
          extraConfig = ''
            tls ${cfg.tlsCert} ${cfg.tlsKey}

            reverse_proxy ${target}
          '';
        })
        cfg.reverseProxies;
    };

    # Open HTTPS port
    networking.firewall.allowedTCPPorts = [80 443];

    systemd.services.caddy = {
      # The cert/key arrive over the host's virtiofs share (/mnt/acme). On a
      # fresh host they do not exist until acme-<domain>.service has run, and
      # upstream's RestartPreventExitStatus=1 means a Caddy that fails to load
      # them is NOT restarted — it would stay dead until someone starts it by
      # hand. Wait for the files (the mount itself is ordered via
      # RequiresMountsFor) before handing over to Caddy.
      unitConfig.RequiresMountsFor = lib.unique [(builtins.dirOf cfg.tlsCert) (builtins.dirOf cfg.tlsKey)];
      preStart = ''
        for _ in $(seq 1 120); do
          if [ -s ${lib.escapeShellArg cfg.tlsCert} ] && [ -s ${lib.escapeShellArg cfg.tlsKey} ]; then
            exit 0
          fi
          sleep 5
        done
        echo "caddy: TLS files ${cfg.tlsCert} / ${cfg.tlsKey} still missing after 10 minutes" >&2
        exit 1
      '';
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      };
    };

    # Caddy loads file-based certificates once at start and never re-reads
    # them. The host renews the wildcard cert in place (and swaps the self-signed
    # placeholder for the real one shortly after a fresh install); virtiofs
    # propagates no inotify events, so poll with a daily graceful reload.
    systemd.services.caddy-reload = {
      description = "Reload Caddy so a renewed shared certificate is served";
      after = ["caddy.service"];
      requisite = ["caddy.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.systemd.package}/bin/systemctl reload caddy.service";
      };
    };
    systemd.timers.caddy-reload = {
      description = "Daily Caddy reload for renewed certificates";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
