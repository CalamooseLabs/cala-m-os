{ username, ... }: { inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.default # Add Home Manager
  ];

  users.users = {
    "${username}" = {
      isNormalUser = true;
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
  };
}
