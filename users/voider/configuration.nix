{username, ...}: {...}: {
  users.users."${username}" = {
    extraGroups = ["wheel" "networkmanager" "disk"];

    openssh.authorizedKeys.keyFiles = [
      ./public_keys/id_ed25519_sk.pub
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

  programs.fuse.userAllowOther = true;

  systemd.services.agenix.after = [
    "basic.target" # Ensures “basic boot-up” runs prior to agenix, including impermanence's bind-mounts
  ];
}
