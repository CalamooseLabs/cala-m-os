# Backend-neutral secret declaration for multichat's YouTube Data API v3 key
# (see modules/secrets/configuration.nix). multichat is enrolled only on the
# broadcast host, which runs the online (Proton Pass) backend — so this secret
# is online-only and carries no agenixFile. To provision it, add an item titled
# "youtube-api-key" to the "Cala-M-OS" Proton Pass vault with the raw key in a
# custom field named "secret" (mirrors admin_password in users/_core/secrets).
{...}: {
  calamoose.secrets."youtube-api-key" = {
    vaultName = "Cala-M-OS";
    itemTitle = "youtube-api-key";
    field = "secret";
  };
}
