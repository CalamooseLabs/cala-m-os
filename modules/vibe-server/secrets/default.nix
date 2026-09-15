# Dedicated PLAINTEXT web-UI login secret for vibe-server.
#
# vibe-server compares the submitted login string against this file's contents
# VERBATIM (constant-time SHA-256 in flakes/vibe-server/app/src/auth.ts) — so this
# file must hold the *plaintext* password you type at the sign-in box.
#
# This is deliberately NOT admin_password: that one is a *crypt hash* ("$y$…"/"$6$…")
# because it feeds users.users.hub.hashedPasswordFile, and reusing it forced you to
# paste the hash itself to sign in. A dedicated plaintext secret fixes that.
#
# vibe-server runs as `hub` and reads passwordFile at runtime, but agenix writes
# secrets root:root 0400 by default → the service would get EACCES. Own it by hub.
{cala-m-os, ...}: {
  calamoose.secrets.vibe_password = {
    agenixFile = ./vibe_password.age;
    owner = cala-m-os.globals.defaultUser;
    # Online-backend parity (Proton Pass vault "Cala-M-OS", item "vibe_password",
    # value in a custom field named "secret"). Unused while devbox stays on agenix,
    # but keeps the secret working if the host is ever switched to enableSecrets="online".
    vaultName = "Cala-M-OS";
    itemTitle = "vibe_password";
    field = "secret";
  };
}
