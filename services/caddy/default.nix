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

    systemd.services.caddy.serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    };
  };
}
