{username, ...}: {pkgs, ...}: {
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
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    mangohud
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${username}/.steam/root/compatibilitytools.d";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  services.lanserver = {
    enable = true;
    port = 8080;
    runAsRoot = true;
    routes = [
      {
        path = "/shutdown";
        method = "GET";
        command = [
          "echo 'Shutting down...'"
          "shutdown 0"
        ];
      }
      {
        path = "/restart";
        method = "GET";
        command = [
          "echo 'Restart...'"
          "sudo reboot"
        ];
      }
      {
        path = "/status";
        method = "POST";
        data = {
          serviceName = "string";
        };
        command = [
          "sudo systemctl status $serviceName"
        ];
      }
      {
        path = "/start-vms";
        method = "GET";
        command = [
          "sudo systemctl start microvm@lanstation-2.service"
          "sudo systemctl start microvm@lanstation-3.service"
          "sudo systemctl start microvm@lanstation-4.service"
        ];
      }
    ];
  };
}
