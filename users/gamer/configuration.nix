{username, ...}: {
  pkgs,
  cala-m-os,
  inputs,
  ...
}: {
  users.users."${username}" = {
    extraGroups = ["wheel" "networkmanager" "disk" "plugdev" "video" "audio" "kvm" "gamemode"];
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
    capSysNice = false;
    args = [
      "--expose-wayland"
    ];
  };

  programs.steam.gamescopeSession.enable = true;

  systemd.services.agenix.after = [
    "basic.target"
  ];

  environment.systemPackages = with pkgs; [
    protonup-qt # GUI for installing custom Proton versions like GE_Proton
    protonup
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${username}/.steam/root/compatibilitytools.d";
  };

  system.activationScripts.setGamesPermissions = ''
    # Set ownership to root:wheel
    chown -R ${cala-m-os.globalDefaultUser}:${cala-m-os.globalAdminGroup} /mnt/games
  '';

  hardware.graphics = {
    package = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mesa;

    # if you also want 32-bit support (e.g for Steam)
    enable32Bit = true;
    package32 = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pkgsi686Linux.mesa;
  };
}
