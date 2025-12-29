{...}: {
  imports = [
    ./modules/hyprland/home.nix
  ];

  geforceNow.gpuType = "nvidia";
}
