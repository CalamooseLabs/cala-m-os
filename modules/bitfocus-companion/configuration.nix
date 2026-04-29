{inputs, ...}: {
  imports = [inputs.companion.nixosModules.default];

  programs.companion.enable = true;
}
