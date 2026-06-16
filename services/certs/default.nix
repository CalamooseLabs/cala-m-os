{
  config,
  cala-m-os,
  lib,
  ...
}: let
  cfg = config.services.cala-certs;
in {
  options.services.cala-certs = {
    enable = lib.mkEnableOption "ACME wildcard certificates via Cloudflare DNS (with DNS-cache hardening)";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "example.com";
      description = "Base domain to request a certificate for (a wildcard *.domain is also issued).";
    };

    tokenPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the environment file holding the Cloudflare API token.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable all DNS Caching
    services.resolved = {
      enable = true;
      # All Resolve-section keys live under settings.Resolve; the older top-level
      # dnssec/domains/fallbackDns/extraConfig options are deprecated/removed.
      settings.Resolve = {
        DNSSEC = "false";
        Domains = ["~."];
        FallbackDNS = ["1.1.1.1" "8.8.8.8"];
        Cache = "no";
        CacheFromLocalhost = "no";
      };
    };

    networking.nameservers = ["1.1.1.1" "8.8.8.8"];

    services.nscd.enable = lib.mkForce false;
    system.nssModules = lib.mkForce [];
    networking.networkmanager.dns = lib.mkForce "none";

    # Create Certs
    security.acme = {
      acceptTerms = true;
      useRoot = true;
      defaults.email = cala-m-os.globals.defaultEmail;

      certs."${cfg.domain}" = {
        domain = cfg.domain;
        dnsProvider = "cloudflare";
        environmentFile = cfg.tokenPath;
        dnsPropagationCheck = true;
        extraDomainNames = ["*.${cfg.domain}"];
        group = "caddy";
      };
    };

    services.caddy.enable = true;
  };
}
