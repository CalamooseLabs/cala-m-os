{username, ...}: {...}: {
  users.users."${username}" = {
    extraGroups = ["wheel"];

    # YubiKey (sk-ssh-ed25519) keys: the key is checked on the CLIENT, so these
    # work on a cloud box that has no YubiKey of its own.
    openssh.authorizedKeys.keyFiles = [
      ./public_keys/id_ed25519_sk.pub
      ./public_keys/backup_id_ed25519_sk.pub
    ];
  };

  # No password exists on a secrets-less box, so remote deploys
  # (`nixos-rebuild --sudo`) need passwordless sudo.
  security.sudo.extraRules = [
    {
      users = ["${username}"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
