{machine_path, ...}: {inputs, ...}: let
  machine_home = toString (machine_path + "/home.nix");
in {
  imports = [
    inputs.home-manager.nixosModules.default # Add Home Manager
  ];

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    backupFileExtension = "hm-backup";

    useGlobalPkgs = true;
    useUserPackages = true;

    sharedModules = [
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
