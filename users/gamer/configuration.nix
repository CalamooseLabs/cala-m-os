{username, ...}: {
  pkgs,
  cala-m-os,
  ...
}: {
  users.users."${username}" = {
    extraGroups = ["wheel" "networkmanager" "disk" "plugdev" "video" "audio" "kvm" "gamemode" "render"];
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

  programs.gamemode.enable = true;

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.steam.gamescopeSession.enable = true;

  systemd.services.agenix.after = [
    "basic.target"
  ];

  environment.systemPackages = with pkgs; [
    protonup
    steam-run
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${username}/.steam/root/compatibilitytools.d";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  system.activationScripts.setGamesPermissions = ''
    # Set ownership global user
    chown -R ${cala-m-os.globalDefaultUser}:${cala-m-os.globalAdminGroup} /mnt/games
  '';
}
