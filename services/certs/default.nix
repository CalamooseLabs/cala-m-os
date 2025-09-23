{
  domain,
  tokenPath,
  target,
}: {
  cala-m-os,
  lib,
  ...
}: {
  # Disable all DNS Caching
  services.resolved = {
    enable = true;
    dnssec = "false";
    domains = ["~."];
    fallbackDns = ["1.1.1.1" "8.8.8.8"];
    extraConfig = ''
      Cache=no
      CacheFromLocalhost=no
    '';
  };

  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  services.nscd.enable = lib.mkForce false;
  system.nssModules = lib.mkForce [];
  networking.networkmanager.dns = lib.mkForce "none";

  # Create Certs
  security.acme = {
    acceptTerms = true;
    useRoot = true;
    defaults.email = cala-m-os.globalDefaultEmail;

    certs."${domain}" = {
      domain = domain;
      dnsProvider = "cloudflare";
      environmentFile = tokenPath;
      dnsPropagationCheck = true;
      group = "acme";
    };
  };

  # Reverse Proxy
  services.caddy = {
    enable = true;

    virtualHosts = {
      "${domain}" = {
        extraConfig = ''
          tls /var/lib/acme/${domain}/cert.pem /var/lib/acme/${domain}/key.pem

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
