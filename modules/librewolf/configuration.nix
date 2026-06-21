{...}: {
  nixpkgs.config.permittedInsecurePackages = [
    "librewolf-151.0.2-1"
  ];
}
