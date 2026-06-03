{username, ...}: {...}: {
  users.users."${username}" = {
    extraGroups = [
      "wheel"
      "networkmanager"
      "disk"
      "video"
      "audio"
      "render"
      "input"
      "plugdev"
    ];

    openssh.authorizedKeys.keyFiles = [
      ./public_keys/id_ed25519_sk.pub
      ./public_keys/backup_id_ed25519_sk.pub
    ];
  };

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

  systemd.services.agenix.after = [
    "basic.target"
  ];
}
