{
  cala-m-os,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    inputs.antlers.nixosModules.vibe-server
    # Declares calamoose.secrets.vibe_password — a dedicated PLAINTEXT login secret.
    # vibe-server compares the submitted login string against passwordFile's contents
    # verbatim, so the file must hold the plaintext you type (NOT a crypt hash). This
    # replaces the old admin_password reuse, which forced pasting the "$y$…" hash.
    ./secrets
  ];

  services.vibe-server = {
    enable = true;
    port = 8080;
    user = cala-m-os.globals.defaultUser;
    group = cala-m-os.globals.userGroup;
    protectHome = false;
    localNetworkOnly = true;
    openFirewall = true;
    commitPush.enable = true;
    passwordFile = lib.mkIf config.calamoose._secretsEnabled config.calamoose.secrets.vibe_password.path;
  };
}
