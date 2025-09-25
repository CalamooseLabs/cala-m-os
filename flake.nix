{
  description = "Cala-M-OS NixOS Configuration Flake";

  inputs = {
    # Unstable NixOS Branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Specific Hardware Fixes
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Theming
    stylix.url = "github:danth/stylix";

    # Impermanence
    impermanence.url = "github:nix-community/impermanence";

    # MicroVM
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland & Plugins
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Disk Partitioning Tool
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

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      system = system;
      overlays = import ./overlays;
    };
    cala-m-os = import ./settings.nix;
    initialInstallMode = builtins.getEnv "INITIAL_INSTALL_MODE" == "1";

    mkSystem = hostname: extraSpecialArgs:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs =
          {
            inherit inputs cala-m-os initialInstallMode;
          }
          // extraSpecialArgs;
        modules = [
          ./hosts/${hostname}/configuration.nix
          {nixpkgs.overlays = import ./overlays;}
        ];
      };
  in {
    nixosConfigurations = {
      devbox = mkSystem "devbox" {};
      ephemeral = mkSystem "ephemeral" {};
      lab = mkSystem "lab" {inherit self;};

      iso = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [./iso/default.nix];
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
