
{ pkgs, ... }:

pkgs.runCommand "plex-desktop-wrapped" {
  buildInputs = [ pkgs.makeWrapper ];
} ''
  mkdir -p $out/bin

  # Create the zed wrapper with inline configuration
  makeWrapper ${pkgs.plex-desktop}/bin/plex-desktop $out/bin/plex-desktop \
    --set QT_STYLE_OVERRIDE ""
''
