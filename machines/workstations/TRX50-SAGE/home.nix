{...}: {
  imports = [
    ../../modules/nvidia-gpu/home.nix
  ];

  # NOTE: the OBS baseline (calamoose.obs seed + homeAssets) moved to the
  # `broadcast` host — see hosts/broadcast/home.nix.
}
