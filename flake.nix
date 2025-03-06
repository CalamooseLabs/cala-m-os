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
    stylix.url = "github:danth/stylix";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Calamoose Labs
    zed-editor.url = "github:CalamooseLabs/flakyherd?dir=wrappers/zed-editor";
    plex-desktop.url = "github:CalamooseLabs/flakyherd?dir=wrappers/plex-desktop";
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

    devShells.${system}.default = import ./shell.nix { inherit inputs; inherit pkgs; };
  };
}
