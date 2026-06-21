{
  description = "Cala-M-OS NixOS Configuration Flake";

  inputs = {
    # Unstable NixOS Branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Specific Hardware Fixes
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Declarative Flatpak
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";

    # Preservation
    preservation.url = "github:nix-community/preservation";

    # Theming
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # MicroVM
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland & Plugins
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
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

    # Arion
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Calamoose Labs
    antlers = {
      url = "github:CalamooseLabs/antlers";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openreturn = {
      url = "github:CalamooseLabs/OpenReturn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quorumcall = {
      url = "github:CalamooseLabs/QuorumCall";
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
      config.allowUnfree = true;
    };
    cala-m-os = import ./settings.nix;
    initialInstallMode = builtins.getEnv "INITIAL_INSTALL_MODE" == "1";

    # Persistent per-host machine overrides (see machine-override.nix).
    machineOverrides = import ./machine-override.nix;

    mkSystem = hostname: extraSpecialArgs: let
      # Live override (installer) takes precedence over the persisted file.
      envOverride = builtins.getEnv "MACHINE_OVERRIDE";
      fileOverride = machineOverrides.${hostname} or null;
      machineOverride =
        if envOverride != ""
        then envOverride
        else if fileOverride != null
        then fileOverride
        else "";
    in
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs =
          {
            inherit inputs cala-m-os initialInstallMode machineOverride;
          }
          // extraSpecialArgs;
        modules = [
          ./hosts/${hostname}/configuration.nix
          {nixpkgs.overlays = import ./overlays;}
        ];
      };
  in {
    nixosConfigurations = {
      lanstation = mkSystem "lanstation" {inherit self;};
      devbox = mkSystem "devbox" {};
      ephemeral = mkSystem "ephemeral" {};
      homelab = mkSystem "homelab" {inherit self;};
      simple = mkSystem "simple" {};
      battlestation = mkSystem "battlestation" {};
      broadcast = mkSystem "broadcast" {};
      openreturn = mkSystem "openreturn" {};
      livedata = mkSystem "livedata" {};
      ai = mkSystem "ai" {};

      iso = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        system = "x86_64-linux";
        modules = [./iso/default.nix];
      };
    };

    formatter = {
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    };

    # Per-host evaluation checks (run by `nix flake check`, or individually with
    # `nix build .#checks.x86_64-linux.<host>`). Forcing each host's
    # `toplevel.drvPath` fully evaluates its module tree — options, assertions,
    # removed/renamed-option errors, and infinite recursion — which is the class
    # of bug that is otherwise only found at rebuild time. Discarding the string
    # context means the check itself is just an `echo`, so this evaluates the
    # systems without realising (building) them. The microvm guests (media,
    # torrent) are validated transitively through `homelab`, whose evaluation
    # forces their toplevels via the vm-manager restart triggers.
    checks.${system} =
      builtins.mapAttrs (
        name: cfg:
          pkgs.runCommand "eval-${name}" {
            drv = builtins.unsafeDiscardStringContext cfg.config.system.build.toplevel.drvPath;
          } ''
            echo "$drv" > $out
          ''
      )
      self.nixosConfigurations;

    packages.x86_64-linux.default = self.nixosConfigurations.iso.config.system.build.isoImage;

    templates = import ./templates;

    devShells.${system}.default = import ./shell.nix {
      inherit inputs;
      inherit pkgs;
    };
  };
}
