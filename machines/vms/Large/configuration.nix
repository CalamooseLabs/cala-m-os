{...}: let
  cores = 8;
  memory = 32;
in {
  imports = [
    (import ../_core/configuration.nix {
      cores = cores;
      memory = memory;
    })
  ];
}
