{
  domain,
  target,
}: {...}: {
  # Reverse Proxy
  services.caddy = {
    enable = true;

    virtualHosts = {
      "${domain}" = {
        extraConfig = ''
          tls /mnt/acme/cert.pem /mnt/acme/key.pem

          reverse_proxy ${target}
        '';
      };
    };
  };

  users.users.caddy.extraGroups = ["acme"];

  # Open HTTPS port
  networking.firewall.allowedTCPPorts = [80 443];

  systemd.services.caddy.serviceConfig.AmbientCapabilities = "CAP_NET_BIND_SERVICE";
}
