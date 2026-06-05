{inputs, ...}: {
  imports = [
    inputs.openreturn.nixosModules.default
  ];

  services.openreturn = {
    enable = true;
    host = "0.0.0.0";
    port = 80;
    runAsRoot = true;
  };
}
