{inputs, ...}: {
  imports = [
    inputs.openreturn.nixosModules.openreturn
  ];

  services.openreturn = {
    enable = true;
    host = "0.0.0.0";
    port = 8000;
  };
}
