{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprlock.url = "github:hyprwm/Hyprlock";

    ghostty.url = "github:ghostty-org/ghostty";

    catppuccin.url = "github:catppuccin/nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations = {
      calamooselabs = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
          inputs.home-manager.nixosModules.default
          inputs.catppuccin.nixosModules.catppuccin
          
          ./hosts/workstations/FW13-12XXP/configuration.nix

          {
            home-manager = {
              extraSpecialArgs = { inherit inputs; };
              users.ccalamos = {
                imports = [
                  inputs.catppuccin.homeManagerModules.catppuccin
                  ./users/ccalamos/home.nix
                ];
              };
            };
          }
        ];
      };
    };
  };
}
