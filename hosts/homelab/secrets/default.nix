# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
# qbit-password + proton-vpn.conf are consumed by the torrent microVM via the
# /run/hostsecrets virtiofs share (see services/vm-manager/default.nix).
{...}: {
  calamoose.secrets = {
    "cloudflare-token" = {
      agenixFile = ./cloudflare-token.age;
      reference = "pass://REPLACE_ME/cloudflare-token";
    };
    "qbit-password" = {
      agenixFile = ./qbit-password.age;
      reference = "pass://REPLACE_ME/qbit-password";
    };
    "proton-vpn.conf" = {
      agenixFile = ./proton-vpn.conf.age;
      reference = "pass://REPLACE_ME/proton-vpn.conf";
    };
  };
}
