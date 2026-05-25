{pkgs, ...}: let
  nbtlib = pkgs.python3Packages.nbtlib;
in {
  programs.bash.initExtra = ''
    nbtedit() {
      local tmp=$(mktemp --suffix=.snbt)
      ${nbtlib}/bin/nbt -r "$1" --pretty > "$tmp" && \
      "''${EDITOR:-nano}" "$tmp" && \
      ${nbtlib}/bin/nbt -s "$tmp" -w "$1"
      rm "$tmp"
    }
  '';
}
