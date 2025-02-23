{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "plex-desktop-wrapper";
  version = "1.0";

  # No source needed if wrapping an existing package
  src = null;

  buildInputs = [
    pkgs.cairo
    pkgs.freetype
    pkgs.plex-desktop
  ];

  # Ensure the correct version of FreeType is used
  preFixup = ''
    wrapProgram $out/bin/plex-desktop \
      --set LD_LIBRARY_PATH ${pkgs.freetype}/lib:${pkgs.cairo}/lib
  '';

  installPhase = ''
    mkdir -p $out/bin
    ln -s ${pkgs.plex-desktop}/bin/plex-desktop $out/bin/
  '';
}
