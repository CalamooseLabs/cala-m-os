{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  environment.systemPackages = [
    inputs.agenix.packages."x86_64-linux".default
    pkgs.age
    pkgs.age-plugin-yubikey
  ];

  age.identityPaths = [
    "${toString ./.}/identities/server.key"
    "${toString ./.}/identities/yubi.key"
    "${toString ./.}/identities/dev.key"
    "${toString ./.}/identities/backup.key"
  ];

  age.ageBin = "PATH=$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey]} ${pkgs.age}/bin/age";
}
