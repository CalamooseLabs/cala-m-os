{ username, ... }: { ... }:

{
  users.users."${username}" = {
    extraGroups = [ "wheel" "networkmanager" ];
  };

  security.sudo.extraRules = [{
    users = [ "${username}" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  home-manager = {
    users."${username}" = {
      imports = [
        # inputs.catppuccin.homeManagerModules.catppuccin
      ];
    };
  };

  fileSystems."/mnt/backups" = {
    device = "nas.calamos.family:/mnt/Media Library/Backups";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
    ];
  };
}
