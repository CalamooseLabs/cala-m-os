{machine_path, ...}: {
  inputs,
  cala-m-os,
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
      # Declarative niri config: provides `programs.niri.settings` (Nix → KDL)
      # without managing the package, which stays on nixpkgs via the niri module.
      inputs.niri-flake.homeModules.config
      {
        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

        # Original State Version
        home.stateVersion = "24.11"; # Please read the comment before changing.
      }
      machine_home
    ];
  };
}
