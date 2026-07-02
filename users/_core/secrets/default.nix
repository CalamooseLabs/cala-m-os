# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
# Fill in the pass:// references before switching a host to enableSecrets = "online".
{...}: {
  calamoose.secrets.admin_password = {
    agenixFile = ./admin_password.age;
    # Online backend: Proton Pass vault "Cala-M-OS", item "admin_password",
    # value stored in a custom field named "secret".
    vaultName = "Cala-M-OS";
    itemTitle = "admin_password";
    field = "secret";
  };
}
