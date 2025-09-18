{...}: let
  cores = 2;
  memory = 4;
in {
  imports = [
    (import ../_core/configuration.nix {
      cores = cores;
      memory = memory;
    })
  ];
}
