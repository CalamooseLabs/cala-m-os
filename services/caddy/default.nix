{
  caddyConfig,
  tokenPath,
}: {pkgs, ...}: let
  transformedConfig = builtins.listToAttrs (
    builtins.concatLists (
      builtins.attrValues (
        builtins.mapAttrs (
          localhost: domains:
            map (domain: {
              name = domain;
              value = {
                extraConfig = ''
                  tls {
                    dns cloudflare {env.CLOUDFLARE_API_TOKEN}
                  }

                  reverse_proxy ${localhost}
                '';
              };
            })
            domains
        )
        caddyConfig
      )
    )
  );
in {
  # Configure Caddy service
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
      hash = "sha256-j+xUy8OAjEo+bdMOkQ1kVqDnEkzKGTBIbMDVL7YDwDY=";
    };

    # Global configuration for Cloudflare DNS
    # globalConfig = ''
    #   acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
    # '';

    # Set all virtual hosts
    virtualHosts = transformedConfig;
  };

  # Link token to Caddy service
  systemd.services.caddy.serviceConfig.EnvironmentFile = tokenPath;

  # Open HTTPS port
  networking.firewall.allowedTCPPorts = [80 443];
}
