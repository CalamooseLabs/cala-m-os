{
  description = "Cala-M-OS NixOS Configuration Flake";

  inputs = {
    # Unstable NixOS Branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Specific Hardware Fixes
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Theming
    stylix.url = "github:danth/stylix";

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

    # Configurations
    FW13-12XXP = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/workstations/FW13-12XXP/configuration.nix
        ./hardware-configuration.nix
      ];
    };

    FW13-11XXP = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/workstations/FW13-11XXP/configuration.nix
        ./hardware-configuration.nix
      ];
    };

    installer = nixpkgs.lib.nixosSystem {
       specialArgs = {inherit inputs;};
       modules = [
         {
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "calamooselabs";

  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.ccalamos = {
    isNormalUser = true;
    description = "Cole J. Calamos";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  services.getty.autologinUser = "ccalamos";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim 
    git
  ];

  services.pcscd.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?

}
       ];
    };
  in {
    nixosConfigurations = {
      FW13-11XXP = FW13-11XXP;
      FW13-12XXP = FW13-12XXP;

      # Default Configuration
      calamooselabs = FW13-12XXP;
      nixos = calamooselabs;
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
