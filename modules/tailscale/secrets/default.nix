{lib, config, ...}: {
  age = lib.mkIf config.calamoose.enableSecrets {
    secrets = {
      "tailscale-preauth-key" = {
        file = ./. + "/tailscale-preauth-key.age";
      };
    };
  };
}
