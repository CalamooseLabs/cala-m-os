{username, ...}: {...}: {
  users.users."${username}" = {
    extraGroups = [
      "wheel"
      "networkmanager"
      "personas"
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

  systemd.services.agenix.after = ["basic.target"];
}
