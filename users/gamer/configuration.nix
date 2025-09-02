{username, ...}: {pkgs, ...}: {
  users.users."${username}" = {
    extraGroups = ["wheel" "networkmanager" "disk" "plugdev"];
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

  programs.gamemode.enable = true; # for performance mode

  environment.systemPackages = with pkgs; [
    mumble # install voice-chat
    protonup-qt # GUI for installing custom Proton versions like GE_Proton
    (retroarch.override {
      cores = with libretro; [
        # decide what emulators you want to include
        puae # Amiga 500
        scummvm
        dosbox
      ];
    })
    teamspeak_client # install voice-chat
  ];
}
