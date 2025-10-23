{username, ...}: {...}: {
  users.users."${username}" = {
    extraGroups = ["wheel" "networkmanager" "disk" "video" "audio"];
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

  services.pcscd.enable = true;

  systemd.services.agenix.after = [
    "basic.target"
  ];
}
