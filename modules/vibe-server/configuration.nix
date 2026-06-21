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
    protectHome = false;
    localNetworkOnly = true;
    openFirewall = true;
    commitPush.enable = true;
  };
}
