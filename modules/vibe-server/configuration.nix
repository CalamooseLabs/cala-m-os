{
  cala-m-os,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [inputs.antlers.nixosModules.vibe-server];

  # Reuse the host admin password as the vibe web-UI login. NOTE: admin_password is
  # stored as a *crypt hash* (it feeds users.users.hub.hashedPasswordFile), and
  # vibe-server takes the passwordFile contents verbatim as the shared login string
  # — so the web-UI credential is the "$6$…" hash itself (paste it to sign in), not
  # a typeable password. A dedicated plaintext secret was the alternative.
  #
  # vibe-server runs as hub:users and reads passwordFile at runtime (no systemd
  # LoadCredential), but agenix writes secrets root:root 0400 by default — so hand
  # admin_password to hub or the service gets EACCES. Scoped to this module, it only
  # applies where vibe-server is imported (devbox); the secret stays root-owned for
  # its hashedPasswordFile use on every other host.
  calamoose.secrets.admin_password.owner = cala-m-os.globals.defaultUser;

  services.vibe-server = {
    enable = true;
    port = 8080;
    user = cala-m-os.globals.defaultUser;
    group = cala-m-os.globals.userGroup;
    protectHome = false;
    localNetworkOnly = true;
    openFirewall = true;
    commitPush.enable = true;
    passwordFile = lib.mkIf config.calamoose._secretsEnabled config.calamoose.secrets.admin_password.path;
  };
}
