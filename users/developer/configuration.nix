{username, ...}: {...}: {
  users.users."${username}" = {
    extraGroups = ["wheel" "networkmanager" "disk" "plugdev"];

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

  # Public GitHub repos to clone on this box, grouped into subfolders.
  services.github-repo-puller = {
    enable = true;
    repos = {
      "github:CalamooseLab/OpenReturn" = "/home/${username}/nkc";
    };
  };
}
