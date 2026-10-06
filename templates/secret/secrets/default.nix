# Backend-neutral secret declaration (see modules/secrets/configuration.nix).
# Consumers read `config.calamoose.secrets.<name>.path`; the facade resolves it
# to /run/agenix/<name> (offline) or /run/proton-secrets/<name> (online).
{...}: {
  calamoose.secrets = {
    "secret" = {
      agenixFile = ./secret.age;
      # Online backend: either a pass:// reference, or vaultName + itemTitle.
      reference = "pass://REPLACE_ME/secret";
    };
  };
}
