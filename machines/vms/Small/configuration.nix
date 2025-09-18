{...}: let
  cores = 4;
  memory = 8;
in {
  imports = [
    (import ../_core/configuration.nix {
      cores = cores;
      memory = memory;
    })
  ];
}
