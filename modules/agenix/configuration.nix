{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [inputs.agenix.nixosModules.default];

  environment.systemPackages = lib.mkIf (config.calamoose._secretsBackend == "agenix") [
    inputs.agenix.packages."x86_64-linux".default
    pkgs.age
    pkgs.age-plugin-yubikey
  ];

  age = lib.mkIf (config.calamoose._secretsBackend == "agenix") {
    identityPaths = [
      "${toString ./.}/identities/server.key"
      "${toString ./.}/identities/yubi.key"
      "${toString ./.}/identities/dev.key"
      "${toString ./.}/identities/backup.key"
    ];
    ageBin = "PATH=$PATH:${lib.makeBinPath [pkgs.age-plugin-yubikey]} ${pkgs.age}/bin/age";
  };
}
