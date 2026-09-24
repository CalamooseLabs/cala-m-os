{
  description = "Cala-M-OS NixOS Configuration Flake";

  inputs = {
    # Unstable NixOS Branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # DaVinci Resolve Studio 21 without dragging the rest of nixpkgs forward.
    nixpkgs-davinci.url = "github:nixos/nixpkgs/d2f67949798825fe853f7c5d0492b8bf016d3f88";

    # Beta channel — a SECOND nixos-unstable pin that rides AHEAD of the main
    # `nixpkgs`. Update it alone with `nix flake update nixpkgs-beta` (the main
    # pin doesn't move), then cherry-pick per host what should come from it:
    #   calamoose.beta.packages = ["obs-studio"];          # swap single attrs host-wide
    #   calamoose.modules."obs-studio".beta = true;        # flip a beta-aware cala module
    # Lets parts of the system be tested/upgraded incrementally; graduate by
    # bumping the main nixpkgs and clearing the beta lists. Options + the
    # betaPkgsFor module pattern live in hosts/_core/options.nix.
    # NOTE: a bare `nix flake update` moves BOTH pins to the same rev (both
    # track nixos-unstable) — beta silently becomes a no-op until the next
    # `nix flake update nixpkgs-beta`. Update inputs by name.
    nixpkgs-beta.url = "github:nixos/nixpkgs/nixos-unstable";

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

    multichat = {
      url = "github:The-Company-Inc-Nerds/multichat";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chatcards = {
      url = "github:The-Company-Inc-Nerds/chat-cards";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The Company, Inc. bookkeeping app (books CLI + services.calamoose-books).
    # PRIVATE repo — hosts that consume it (devbox) must hand Nix a
    # GitHub PAT at fetch time (see modules/nix-github-token + each host's wiring).
    bookkeeper = {
      url = "github:The-Company-Inc-Nerds/bookkeeper-app";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The Cobblemon Initiative — dedicated-server fleet module (hub + warden +
    # on-demand per-player instances), consumed by the tci-cloud/tci-private
    # hosts via modules/tci-server. We use only `nixosModules.tci-server`
    # (nix/tci-server.nix), a plain module built against THIS flake's nixpkgs;
    # the game bundle itself is deployed out-of-band by `nix run .#deploy-server`
    # from the mod repo, not through this input. PRIVATE repo — the consuming
    # hosts enable modules/nix-github-token so Nix can fetch it (same PAT wiring
    # as bookkeeper). Tracks the default branch (main), where the module lives.
    cobblemon-initiative = {
      url = "github:The-Company-Inc-Nerds/the-cobblemon-initiative";
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
          # Surgical DaVinci Resolve Studio 21 pin (see nixpkgs-davinci input). Lazy:
          # only forced on the host that actually uses davinci-resolve-studio
          # (battlestation), so other hosts don't evaluate the second nixpkgs.
          {
            nixpkgs.overlays = [
              (_final: _prev: {
                davinci-resolve-studio =
                  (import inputs.nixpkgs-davinci {
                    inherit system;
                    config.allowUnfree = true;
                  })
                  .davinci-resolve-studio;
              })
            ];
          }
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

      # The Cobblemon Initiative dedicated servers.
      # tci-cloud   — Hetzner Cloud (US), internet-facing hub (co-op OR solo).
      # tci-private — local LAN box, internal soul-link (shared-fate) fleet.
      tci-cloud = mkSystem "tci-cloud" {};
      tci-private = mkSystem "tci-private" {};

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
