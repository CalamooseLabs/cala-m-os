{lib, config, ...}: {
  age = lib.mkIf config.calamoose.enableSecrets {
    secrets = {
      "yubigpg.asc" = {
        file = ./. + "/yubigpg.asc.age";
      };
    };
  };
}
