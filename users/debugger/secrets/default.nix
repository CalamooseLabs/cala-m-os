{lib, config, ...}: {
  age = lib.mkIf config.calamoose.enableSecrets {
    secrets = {
      "work_credentials" = {
        file = ./. + "/work_credentials.age";
      };
      "proton_vpn.conf" = {
        file = ./. + "/proton_vpn.conf.age";
      };
    };
  };
}
