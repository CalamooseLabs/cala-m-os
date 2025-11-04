{inputs, ...}: {
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  # imports = [
  #   inputs.nix-flatpak.nixosModules.nix-flatpak
  #   ./module.nix
  # ];

  # services.geforce-now.enable = true;
}
