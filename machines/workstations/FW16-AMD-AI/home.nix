{lib, ...}: {
  imports = [
    ./modules/hyprland/home.nix
  ];

  options.geforceNow.gpuType = lib.mkOption {
    type = lib.types.enum ["intel" "nvidia" "amd"];
    default = "amd";
    description = "GPU type for GeForce NOW optimization";
  };

  config.geforceNow.gpuType = "nvidia";
}
