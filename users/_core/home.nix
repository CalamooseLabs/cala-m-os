{ ... }:

{

  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Original State Version
  home.stateVersion = "24.11"; # Please read the comment before changing.
}
