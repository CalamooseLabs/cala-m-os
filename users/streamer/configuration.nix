{username, ...}: {
  config,
  pkgs,
  ...
}: {
  # OBS kiosk launcher — now the shared modules/obs-kiosk (deduped with niri).
  imports = [../../modules/obs-kiosk/configuration.nix];

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

  # Bind the Companion admin UI to this box's NIC (the first IP on enp66s0).
  services.bitfocus-companion = {
    adminInterface = "enp66s0";
    openFirewall = true;
  };
}
