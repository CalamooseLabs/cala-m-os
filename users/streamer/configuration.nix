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
