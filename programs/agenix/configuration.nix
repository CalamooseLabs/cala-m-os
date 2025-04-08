{inputs, ...}: {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  environment.systemPackages = [inputs.agenix.packages."x86_64-linux".default];

  age.identityPaths = [
    "/home/ccalamos/cala-m-os/programs/agenix/identities/yubi.key"
  ];
}
