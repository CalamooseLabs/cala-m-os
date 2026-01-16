{...}: {
  imports = [
    ./configs/fw13.nix
    ./configs/fw16.nix
  ];

  services.easyeffects = {
    enable = true;
  };
}
