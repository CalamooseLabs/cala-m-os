{...}: {pkgs, ...}: {
  home.packages = with pkgs; [
    imagemagick # Image manipulation
    proton-pass # Password manager
    spotify # Spotify music player
    cifs-utils # Samba mounting
    sops # Manage Secrets
  ];
}
