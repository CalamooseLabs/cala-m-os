# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
{...}: {
  calamoose.secrets."yubigpg.asc" = {
    agenixFile = ./yubigpg.asc.age;
    # Online backend: Proton Pass vault "Cala-M-OS", item "yubigpg.asc" — a Secure
    # Note whose body is the exported public key. If the note body isn't returned
    # cleanly, set `field` to the field that holds it — verify with:
    #   pass-cli item view --vault-name Cala-M-OS --item-title yubigpg.asc --output json
    vaultName = "Cala-M-OS";
    itemTitle = "yubigpg.asc";
  };
}
