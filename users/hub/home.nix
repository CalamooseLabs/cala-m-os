{ ... }: { pkgs, ... }:

{
  home.packages = with pkgs; [
    imagemagick # Image manipulation
    proton-pass # Password manager
    spotify # Spotify music player
  ];

  catppuccin.enable = true;
}
