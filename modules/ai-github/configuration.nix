# ai-github — dedicated bot GitHub identity glue for the `ai` host.
#
# `ai` is a headless, impermanent box that pushes signed commits to a SEPARATE
# "ai" GitHub account, distinct from the personal 50D56BF0B93CA212 identity. It
# uses its own on-card OpenPGP key whose PUBLIC half lives in Proton Pass and is
# imported via gpg-key-import. SSH auth to GitHub rides the OpenPGP [A]
# (authentication) subkey served over the gpg-agent SSH socket (the `gpg` module
# sets enableSSHSupport = true) — GitHub accepts it as an ordinary ed25519 key,
# and the card's touch policy = off gives the present-but-no-touch behaviour a
# headless box needs. We deliberately do NOT use a FIDO2/sk key: GitHub rejects
# no-touch sk keys for authentication.
#
# Provision the key with `yubikey-github-bootstrap`; it prints the key id + the
# Proton Pass item to create. Then fill REPLACE_ME_BOT_KEYID below and rebuild.
#
# Only `ai` imports this module (via its extra_user_modules), so the online-only
# secret declaration below never reaches an agenix host.
{...}: {
  # The bot's PUBLIC key, stored in Proton Pass (vault "Cala-M-OS", item
  # "ai-github-gpg.asc", custom field "secret"). Online backend only — `ai` sets
  # enableSecrets = "online", so no agenixFile is required here.
  calamoose.secrets."ai-github-gpg.asc" = {
    vaultName = "Cala-M-OS";
    itemTitle = "ai-github-gpg.asc";
    field = "secret";
  };

  # Import the bot public key (not the shared yubigpg.asc) under the bot key id,
  # so `gpg-key-import` populates the keyring with the ai identity.
  programs.gpg-key-import.secretName = "ai-github-gpg.asc";
  programs.gpg-key-import.keyId = "REPLACE_ME_BOT_KEYID"; # <- from yubikey-github-bootstrap

  # Pin GitHub's SSH host key so the headless box never blocks on a TOFU prompt
  # the first time it talks to github.com. Verify against GitHub's published
  # fingerprints: https://docs.github.com/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
}
