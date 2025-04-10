{
  description = "Cala-M-OS Configuration Flake";

  inputs = {
    # Unstable NixOS Branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Specific Hardware Fixes
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Theming
    stylix.url = "github:danth/stylix";

    # Disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Agenix (Secret management)
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Calamoose Labs
    antlers = {
      url = "github:CalamooseLabs/antlers/flakes?dir=flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      system = system;
    };
  in {
    nixosConfigurations = {
      calamooselabs = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/workstations/FW13-12XXP/configuration.nix
        ];
      };

      FW13-12XXP = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/workstations/FW13-12XXP/configuration.nix
        ];
      };

      FW13-11XXP = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/workstations/FW13-11XXP/configuration.nix
          inputs.disko.nixosModules.disko
        ];
      };

      isoImage = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ({modulesPath, ...}: {
            imports = [
              "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
              ./hosts/workstations/FW13-11XXP/configuration.nix
            ];
            networking.wireless.enable = false;

            nixpkgs.hostPlatform = "x86_64-linux";
          })
          inputs.disko.nixosModules.disko
        ];
      };
    };

    formatter = {
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    };

    templates = import ./templates;

    devShells.${system}.default = import ./shell.nix {
      inherit inputs;
      inherit pkgs;
    };
  };
}
