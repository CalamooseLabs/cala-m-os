{
  inputs,
  pkgs,
  ...
}: {
  # `chromium-ephemeral` (antlers): ungoogled-chromium with a throwaway, deleted-
  # on-exit profile. A zero-config wrapper, so it's consumed as a plain package
  # (like plex-desktop) rather than through programs.antlers-scripts. Renamed from
  # the old `chromium` wrapper so it no longer shadows pkgs.chromium — invoke it as
  # `chromium-ephemeral [url]`.
  home.packages = [inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.chromium-ephemeral];
}
