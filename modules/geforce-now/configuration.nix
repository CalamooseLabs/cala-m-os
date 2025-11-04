{inputs, ...}: {
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
}
