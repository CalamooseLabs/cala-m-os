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

  # Public GitHub repos clonable on this box, grouped into subfolders.
  # Run `github-repo-puller` to clone/fast-forward them on demand.
  programs.github-repo-puller = {
    enable = true;
    repos = {
      "github:CalamooseLab/OpenReturn" = "/home/${username}/nkc";
    };
  };

  # Ship the `ssh-key-import` helper (extract the Yubikey resident SSH keys).
  programs.ssh-key-import.enable = true;

  # Ship the `gpg-key-import` helper (import the Yubikey GPG public key).
  programs.gpg-key-import.enable = true;
}
