{inputs, ...}: {
  imports = [inputs.antlers.nixosModules.vibe];

  programs.vibe = {
    enable = true;
    model = "opus[1m]";
    effort = "xhigh";
    remoteControl.enable = true;
    ultracode = true;
  };
}
