{...}: {
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
  services.flatpak = {
    enable = true;
  };
}
