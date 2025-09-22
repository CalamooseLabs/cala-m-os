{caddyConfig}: {
  lib,
  pkgs,
  ...
}: let
  caddyWithCloudflare = pkgs.caddy.withPlugins {
    plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
    hash = "sha256-j+xUy8OAjEo+bdMOkQ1kVqDnEkzKGTBIbMDVL7YDwDY=";
  };

  serviceDefaults = {
    extraHeaders = {};
    enableWebsocket = true;
    flushInterval = "-1";
    customConfig = "";
  };

  normalizedConfig =
    lib.mapAttrs (
      target: cfg:
        serviceDefaults // cfg
    )
    caddyConfig;

  # Generate header directives
  mkHeaders = headers:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: value: "header_up ${name} ${value}"
      )
      headers
    );

  # Generate reverse proxy config for each alias
  mkReverseProxy = target: cfg: alias: {
    name = alias;
    value = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }

        reverse_proxy ${target} {
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-Host {host}
          header_up X-Real-IP {remote_host}
          ${lib.optionalString cfg.enableWebsocket ''
          header_up Upgrade {header.Upgrade}
          header_up Connection {header.Connection}
        ''}
          ${mkHeaders cfg.extraHeaders}
          flush_interval ${cfg.flushInterval}
        }

        ${cfg.customConfig}
      '';
    };
  };

  # Generate all virtual hosts from configuration
  allVirtualHosts = lib.listToAttrs (
    lib.flatten (
      lib.mapAttrsToList (
        target: cfg:
          map (mkReverseProxy target cfg) cfg.aliases
      )
      normalizedConfig
    )
  );

  # Get first token path (assuming single token for simplicity)
  tokenPath = (lib.head (lib.attrValues normalizedConfig)).tokenPath;
in {
  # Configure Caddy service
  services.caddy = {
    enable = true;
    package = caddyWithCloudflare;

    # Global configuration for Cloudflare DNS
    globalConfig = ''
      acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
    '';

    # Set all virtual hosts
    virtualHosts = allVirtualHosts;
  };

  # Link token to Caddy service
  systemd.services.caddy = {
    serviceConfig = {
      EnvironmentFile = [tokenPath];
    };
  };

  # Open HTTPS port
  networking.firewall.allowedTCPPorts = [443];
}
