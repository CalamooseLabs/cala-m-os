{ inputs, ... }:

{
  users.users.ccalamos = {
    extraGroups = [ "wheel" "networkmanager" ];
  };

  security.sudo.extraRules = [{
    users = [ "ccalamos" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  home-manager = {
    users.ccalamos = {
      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin
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
