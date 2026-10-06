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

    # Pre-create the certificate directory at boot. It is otherwise created
    # only as the StateDirectory of acme-<domain>.service, which races the
    # guests' virtiofs daemons on a fresh host (hosts/homelab/vms.nix shares it
    # into media/torrent); a virtiofsd whose --shared-dir does not exist fails,
    # and the guest that Requires it is then never started. Ownership matches
    # what the acme module enforces for the cert's group.
    systemd.tmpfiles.rules = ["d /var/lib/acme/${cfg.domain} 0750 acme caddy - -"];

    # The order/renew unit reads the Cloudflare token via EnvironmentFile; on the
    # agenix backend that file only appears once agenix-rerun has decrypted it
    # post-boot (see modules/agenix). Without this ordering the boot-time order
    # fails on a fresh host and nothing retries until the daily renew timer (up
    # to 24h of jitter), leaving the guests on the self-signed placeholder cert.
    systemd.services."acme-order-renew-${cfg.domain}" = lib.mkMerge [
      (lib.mkIf (config.calamoose._secretsBackend == "agenix") {
        after = ["agenix-rerun.service"];
        wants = ["agenix-rerun.service"];
      })
      {
        # A fresh box may boot with a wrong clock (dead RTC battery) or before
        # DNS is usable; TLS to the CA and the DNS-01 check both need both.
        # Upstream sets RestartSec=15min but no Restart=, so a failed first order
        # otherwise waits for the daily timer (plus up to 24h of jitter).
        after = ["time-sync.target"];
        wants = ["time-sync.target"];
        serviceConfig.Restart = "on-failure";
      }
    ];
  };
}
