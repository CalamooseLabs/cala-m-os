{inputs, ...}: {
  # `restore-config` (antlers): repair the Nix store, `nh os switch`, restart NM.
  imports = [inputs.antlers.homeManagerModules.antlers-scripts];
  programs.antlers-scripts = {
    enable = true;
    restore-config.enable = true;
  };
}
