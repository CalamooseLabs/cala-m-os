{
  domain,
  tokenPath,
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
      extraDomainNames = ["*.${domain}"];
      group = "acme";
    };
  };
}
