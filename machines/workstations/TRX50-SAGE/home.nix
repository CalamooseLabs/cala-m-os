{...}: {
  imports = [
    ../../modules/nvidia-gpu/home.nix
  ];

  # Seed the committed OBS baseline (profiles + scene collections) into this box
  # on first activation, then let the machine own it. Populate the baseline from a
  # running box with `obs-config-snapshot`; push it back with `obs-config-restore`.
  # See ./obs/README.md. Scenes reference this box's Decklink/capture devices, so
  # the baseline lives with the machine rather than in the shared obs-studio module.
  #
  # seedSource auto-wires only once a real baseline (basic/ or global.ini) is
  # committed — until then it stays null so OBS starts fresh like a normal install.
  # `obs-config-snapshot` keys off repoPath, so it is available to capture that
  # first baseline even while seedSource is null. Mirrors the bitfocus seedDb guard.
  calamoose.obs = {
    seedSource = let
      p = ./obs;
    in
      if builtins.pathExists (p + "/basic") || builtins.pathExists (p + "/global.ini")
      then p
      else null;
    repoPath = "/etc/nixos/machines/workstations/TRX50-SAGE/obs";
  };
}
