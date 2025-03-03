{
  description = "Cala-M-OS Base Configuration Flake";

  inputs = {
    # Unstable NixOS Branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Specific Hardware Fixes
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Ghostty Terminal
    ghostty.url = "github:ghostty-org/ghostty";

    # Theme
    catppuccin.url = "github:catppuccin/nix";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... } @ inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { system = system; };
  in
  {
    nixosConfigurations = {
      calamooselabs = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/workstations/FW13-12XXP/configuration.nix
        ];
      };
    };

    templates = import ./templates;

    devShells.${system}.default = import ./shell.nix { inherit pkgs; };
  };
}
