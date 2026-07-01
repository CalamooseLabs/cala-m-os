# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
{...}: {
  calamoose.secrets."yubigpg.asc" = {
    agenixFile = ./yubigpg.asc.age;
    reference = "pass://REPLACE_ME/yubigpg.asc";
  };
}
