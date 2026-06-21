{inputs, ...}: {
  # `pi-imager` (antlers): Raspberry Pi Imager with the Wayland/fusion Qt env set.
  imports = [inputs.antlers.homeManagerModules.antlers-scripts];
  programs.antlers-scripts = {
    enable = true;
    pi-imager.enable = true;
  };
}
