{
  inputs,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  # Fade In screenwriting app — now from the antlers flake (relocated from the
  # former ./fadein.nix + ./packages/ tarball).
  environment.systemPackages = [
    inputs.antlers.packages.${pkgs.system}.fadein
  ];

  # Screenwriting fonts
  fonts.packages = with pkgs; [
    courier-prime
    liberation_ttf
    dejavu_fonts
  ];
}
