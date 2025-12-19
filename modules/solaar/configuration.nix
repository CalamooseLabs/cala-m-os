{
  inputs,
  pkgs,
  ...
}: {
  # imports = [
  #   inputs.solaar.nixosModules.default
  # ];
  environment.systemPackages = [
    pkgs.solaar
  ];

  # services.solaar.enable = true;

  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };
}
