{pkgs, ...}: let
  fadein = pkgs.callPackage ./fadein.nix {};
in {
  # Allow unfree packages (Fade In is proprietary)
  nixpkgs.config.allowUnfree = true;

  # Install Fade In
  environment.systemPackages = [fadein];

  # Install screenwriting fonts
  fonts.packages = with pkgs; [
    courier-prime # Screenwriting font (similar to Courier Screenplay)
    liberation_ttf # Good fallback fonts
    dejavu_fonts
  ];
}
