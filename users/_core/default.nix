{ inputs, ... }:

{
  imports = [
    # Home Manager
    inputs.home-manager.nixosModules.default
  ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
  };
}
