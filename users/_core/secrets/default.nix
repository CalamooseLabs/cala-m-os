# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
# Fill in the pass:// references before switching a host to enableSecrets = "online".
{...}: {
  calamoose.secrets.admin_password = {
    agenixFile = ./admin_password.age;
    # Online backend: Proton Pass vault "Cala-M-OS", item "admin_password".
    # field assumes a Login item (hash in the password field). If it's a Secure
    # Note instead, drop `field` or point it at the right one — verify with:
    #   pass-cli item view --vault-name Cala-M-OS --item-title admin_password --output json
    vaultName = "Cala-M-OS";
    itemTitle = "admin_password";
    field = "password";
  };
}
