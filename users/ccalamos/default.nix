{ inputs, ... }:

{
  imports = [
    # Home Manager
    inputs.home-manager.nixosModules.default
  ];

  users.users.ccalamos = {
    isNormalUser = true;
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
    extraSpecialArgs = { inherit inputs; };
    users.ccalamos = {
      imports = [
        inputs.catppuccin.homeManagerModules.catppuccin
        ./home.nix
      ];
    };
  };
}
