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
      };
      "Cala-M-OS" = {
        directories = ["/etc/nixos"];
      };
      "OpenReturn" = {
        directories = ["/home/hub/01 - Projects/nkc/OpenReturn" "/home/hub/01 - Projects/nkc/OpenReturn-UI"];
      };
      "Kintsugi" = {
        directories = ["/home/hub/01 - Projects/calamooselabs/kintsugi"];
      };
      "CalamooseLabs" = {
        directories = ["/etc/nixos" "/home/hub/01 - Projects/calamooselabs/antlers"];
      };
    };
  };
}
