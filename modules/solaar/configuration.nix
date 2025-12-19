{inputs, ...}: {
  imports = [
    inputs.solaar.nixosModules.default
  ];

  services.solaar.enable = true;

  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };
}
