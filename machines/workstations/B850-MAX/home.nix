{
  lib,
  options,
  ...
}: {
  imports = [
    ./modules/hyprland/home.nix
  ];

  # Applied to every user via sharedModules, but geforceNow only exists for
  # users that import the geforce-now module. Guard it so personas without
  # the module don't fail evaluation.
  config = lib.optionalAttrs (options ? geforceNow) {
    geforceNow.gpuType = "nvidia";
  };
}
