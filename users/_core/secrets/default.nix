# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
# Fill in the pass:// references before switching a host to enableSecrets = "online".
{...}: {
  calamoose.secrets.admin_password = {
    agenixFile = ./admin_password.age;
    reference = "pass://REPLACE_ME/admin_password";
  };
}
