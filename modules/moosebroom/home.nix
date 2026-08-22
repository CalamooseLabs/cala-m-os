{
  inputs,
  pkgs,
  ...
}: {
  # moosebroom (antlers): storage-space cleaner-upper TUI. Scans three categories
  # of reclaimable space — Nix generations/GC/store-optimise, caches & junk, and
  # dev/container junk — each shown with an estimate you mark and reclaim behind a
  # confirm, plus an ncdu-style disk-usage scan mode to hunt large dirs/files. It
  # reclaims by shelling out to the host's own nix / journalctl / docker (the
  # package wraps a PATH suffix, so the running host's tools win). Launch
  # `moosebroom`; press ? in the TUI for keys. See
  # github:CalamooseLabs/antlers#flakes/moosebroom.
  home.packages = [inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.moosebroom];
}
