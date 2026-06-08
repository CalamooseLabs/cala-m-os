{lib, config, ...}: {
  age = lib.mkIf config.calamoose.enableSecrets {
    secrets = {
      "admin_password" = {
        file = ./. + "/admin_password.age";
      };
    };
  };
}
