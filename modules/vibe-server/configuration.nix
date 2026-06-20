{
  cala-m-os,
  inputs,
  ...
}: {
  imports = [inputs.antlers.nixosModules.vibe-server];

  services.vibe-server = {
    enable = true;
    port = 8080;
    user = cala-m-os.globals.defaultUser;
    group = cala-m-os.globals.userGroup;
    directories = [
      {
        name = "antlers";
        path = "/home/hub/01 - Projects/calamooselabs/antlers";
      }
      {
        name = "cala-m-os";
        path = "/etc/nixos";
      }
      {
        name = "OpenReturn";
        path = "/home/hub/01 - Projects/nkc/OpenReturn";
      }
      {
        name = "OpenReturn-UI";
        path = "/home/hub/01 - Projects/nkc/OpenReturn-UI";
      }
    ];
    openFirewall = true;
  };
}
