{inputs, ...}: {
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  imports = [
    inputs.flatpaks.nixosModules.default
    ./module.nix
  ];

  services.geforce-now.enable = true;
}
