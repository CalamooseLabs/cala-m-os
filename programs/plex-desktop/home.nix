{ inputs, ... }:

{
  home.packages = [
    inputs.plex-desktop.packages.x86_64-linux.default
  ];
}
