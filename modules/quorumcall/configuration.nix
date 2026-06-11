{inputs, ...}: {
  imports = [
    inputs.quorumcall.nixosModules.default
  ];

  services.quorumcall = {
    enable = true;
    host = "0.0.0.0";
    port = 80;
  };
}
