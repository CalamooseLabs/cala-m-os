{...}: {
  imports = [
    ../../modules/nvidia-gpu/home.nix
  ];

  # Seed the committed OBS baseline (profiles + scene collections) into this box
  # on first activation, then let the machine own it. Populate the baseline from a
  # running box with `obs-config-snapshot`; push it back with `obs-config-restore`.
  # See ./obs/README.md. Scenes reference this box's Decklink/capture devices, so
  # the baseline lives with the machine rather than in the shared obs-studio module.
  calamoose.obs = {
    seedSource = ./obs;
    repoPath = "/etc/nixos/machines/workstations/TRX50-SAGE/obs";
  };
}
