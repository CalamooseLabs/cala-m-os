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
}
