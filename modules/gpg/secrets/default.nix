# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
{...}: {
  calamoose.secrets."yubigpg.asc" = {
    agenixFile = ./yubigpg.asc.age;
    # Online backend: Proton Pass vault "Cala-M-OS", item "yubigpg.asc",
    # value (the exported public key) stored in a custom field named "secret".
    vaultName = "Cala-M-OS";
    itemTitle = "yubigpg.asc";
    field = "secret";
  };
}
