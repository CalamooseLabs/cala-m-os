{ pkgs, ... }:

{
  home.packages = [
    (import ../../wrappers/plex-desktop { inherit pkgs; })
  ];
}
