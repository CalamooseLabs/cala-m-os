# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
{...}: {
  calamoose.secrets."tailscale-preauth-key" = {
    agenixFile = ./tailscale-preauth-key.age;
    reference = "pass://REPLACE_ME/tailscale-preauth-key";
  };
}
