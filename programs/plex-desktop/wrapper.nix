
{ pkgs ? import <nixpkgs> {} }:

pkgs.buildFHSUserEnv {
  name = "plex-desktop-fhs";
  targetPkgs = pkgs: [
    pkgs.cairo
    pkgs.freetype
    pkgs.plex-desktop
  ];
  runScript = "${pkgs.plex-desktop}/bin/plex-desktop";
}
