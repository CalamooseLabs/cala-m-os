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
    "${builtins.toString ./.}/identities/server.key"
    "${builtins.toString ./.}/identities/yubi.key"
    "${builtins.toString ./.}/identities/dev.key"
    "${builtins.toString ./.}/identities/backup.key"
  ];

  age.ageBin = "PATH=$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey]} ${pkgs.age}/bin/age";

  systemd.user.services.agenix = {
    serviceConfig = {
      Environment = "PATH=$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey]} ${pkgs.age}/bin/age";
    };
  };
}
