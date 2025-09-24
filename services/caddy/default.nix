{reverse_proxies}: {...}: {
  # Reverse Proxy
  services.caddy = {
    enable = true;

    virtualHosts =
      builtins.mapAttrs (domain: target: {
        extraConfig = ''
          tls /mnt/acme/cert.pem /mnt/acme/key.pem

          reverse_proxy ${target}
        '';
      })
      reverse_proxies;
  };

  # Open HTTPS port
  networking.firewall.allowedTCPPorts = [80 443];

  systemd.services.caddy.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
    AmbientCapabilities = "CAP_NET_BIND_SERVICE";
  };
}
