{
  pkgs,
  inputs,
  lib,
  enable_secrets ? true,
  ...
}: {
  imports = lib.optional enable_secrets inputs.agenix.nixosModules.default;

  environment.systemPackages = lib.mkIf enable_secrets [
    inputs.agenix.packages."x86_64-linux".default
    pkgs.age
    pkgs.age-plugin-yubikey
  ];

  age = lib.mkIf enable_secrets {
    identityPaths = [
      "${toString ./.}/identities/server.key"
      "${toString ./.}/identities/yubi.key"
      "${toString ./.}/identities/dev.key"
      "${toString ./.}/identities/backup.key"
    ];
    ageBin = "PATH=$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey]} ${pkgs.age}/bin/age";
  };
}
