{inputs, ...}: {
  imports = [inputs.antlers.nixosModules.vibe];

  programs.vibe = {
    enable = true;
    model = "opus[1m]";
    effort = "xhigh";
    remoteControl.enable = true;
    ultracode = true;
    permissionMode = "auto";
    presets = {
      "Antlers" = {
        directories = ["/home/hub/01 - Projects/calamooselabs/antlers"];
        pushRequiresTouch = true;
      };
      "Cala-M-OS" = {
        directories = ["/etc/nixos"];
        pushRequiresTouch = true;
      };
      "OpenReturn" = {
        directories = ["/home/hub/01 - Projects/nkc/OpenReturn" "/home/hub/01 - Projects/nkc/OpenReturn-UI"];
        pushRequiresTouch = true;
      };
      "Kintsugi" = {
        directories = ["/home/hub/01 - Projects/calamooselabs/kintsugi"];
        pushRequiresTouch = true;
      };
      "CalamooseLabs" = {
        directories = ["/etc/nixos" "/home/hub/01 - Projects/calamooselabs/antlers"];
        pushRequiresTouch = true;
      };
    };
  };
}
