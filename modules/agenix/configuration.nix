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

  systemd.services.agenix-rerun = {
    description = "Rerun agenix decryption after boot";
    after = ["pcscd.service"];
    requires = ["pcscd.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Rerun the activation script
      /run/current-system/activate
    '';
  };
}
