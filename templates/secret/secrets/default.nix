{lib, enable_secrets ? true, ...}: {
  age = lib.mkIf enable_secrets {
    secrets = {
      "secret" = {
        file = ./. + "/secret.age";
      };
    };
  };
}
