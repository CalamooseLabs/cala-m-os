{inputs, ...}: {
  # `edit-config` (antlers): open the NixOS config in zeditor via `direnv exec`.
  imports = [inputs.antlers.homeManagerModules.antlers-scripts];
  programs.antlers-scripts = {
    enable = true;
    edit-config.enable = true;
  };
}
