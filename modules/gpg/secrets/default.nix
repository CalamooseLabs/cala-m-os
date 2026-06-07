{lib, enable_secrets ? true, ...}: {
  age = lib.mkIf enable_secrets {
    secrets = {
      "yubigpg.asc" = {
        file = ./. + "/yubigpg.asc.age";
      };
    };
  };
}
