{username, ...}: {pkgs, ...}: {
  users.users."${username}" = {
    extraGroups = ["wheel" "networkmanager" "disk" "plugdev" "video" "audio"];
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

  home-manager = {
    users."${username}" = {
      imports = [
      ];
    };
  };

  programs.gamemode.enable = true;

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.steam.gamescopeSession.enable = true;

  # Auto-launch Steam Big Picture Mode
  systemd.user.services.steam-big-picture = {
    description = "Steam Big Picture Mode";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = "${pkgs.steam}/bin/steam -bigpicture";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  environment.systemPackages = with pkgs; [
    protonup-qt # GUI for installing custom Proton versions like GE_Proton
    protonup
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${username}/.steam/root/compatibilitytools.d";
  };
}
