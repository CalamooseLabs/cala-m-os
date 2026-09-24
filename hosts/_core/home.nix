{machine_path, ...}: {
  inputs,
  cala-m-os,
  config,
  ...
}: let
  machine_home = toString (machine_path + "/home.nix");
in {
  imports = [
    inputs.home-manager.nixosModules.default # Add Home Manager
  ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit cala-m-os;
    };
    backupFileExtension = "hm-backup";

    useGlobalPkgs = true;
    useUserPackages = true;

    sharedModules = [
      {
        # Hand home-manager modules the same beta selector NixOS modules get
        # (see calamoose.beta.* in ./options.nix) — a beta-aware module's
        # home.nix does `pkgs = betaPkgsFor "<name>";` exactly like its
        # configuration.nix. useGlobalPkgs already carries the
        # calamoose.beta.packages overlay into HM; this covers the
        # module-level switch.
        _module.args.betaPkgsFor = config.calamoose.beta._pkgsFor;

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

        # Original State Version
        home.stateVersion = "24.11"; # Please read the comment before changing.
      }
      machine_home
    ];
  };
}
