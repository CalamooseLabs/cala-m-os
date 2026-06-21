{inputs, ...}: {
  # `rebuild-config` now ships from the antlers scripts collection: lazygit (when
  # the tree is dirty) then `nh os switch`. configPath defaults to /etc/nixos;
  # override with programs.antlers-scripts.rebuild-config.configPath if needed.
  imports = [inputs.antlers.homeManagerModules.antlers-scripts];
  programs.antlers-scripts = {
    enable = true;
    rebuild-config.enable = true;
  };
}
