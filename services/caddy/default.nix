{
  caddyConfig,
  tokenPath,
}: {
  lib,
  pkgs,
  ...
}: let
  mkReverseProxy = listenAddr: domain: {
    ${domain} = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }

        reverse_proxy ${listenAddr}
      '';
    };
  };

  virtualHosts =
    lib.attrsets.mapAttrs' (
      listenAddr: domains:
        lib.lists.listToAttrs (
          map (domain: mkReverseProxy listenAddr domain) domains
        )
    )
    caddyConfig;
in {
  # Configure Caddy service
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
      hash = "sha256-2D7dnG50CwtCho+U+iHmSj2w14zllQXPjmTHr6lJZ/A=";
    };

    # Global configuration for Cloudflare DNS
    # globalConfig = ''
    #   acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
    # '';

    # Set all virtual hosts
    virtualHosts = virtualHosts;
  };

  # Link token to Caddy service
  systemd.services.caddy.serviceConfig.EnvironmentFile = tokenPath;

  # Open HTTPS port
  networking.firewall.allowedTCPPorts = [80 443];
}
