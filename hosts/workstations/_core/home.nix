{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.default # Add Home Manager
  ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-backup";

    useGlobalPkgs = true;
    useUserPackages = true;

    sharedModules = [
      {
        # Allow unfree packages
        # nixpkgs.config.allowUnfree = true;

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

        # Original State Version
        home.stateVersion = "24.11"; # Please read the comment before changing.
      }
    ];
  };
}
