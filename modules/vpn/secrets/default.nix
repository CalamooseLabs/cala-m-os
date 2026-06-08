{lib, config, ...}: {
  age = lib.mkIf config.calamoose.enableSecrets {
    secrets = {
      "CasaMosVPN.nmconnection" = {
        file = ./. + "/CasaMosVPN.nmconnection.age";
      };
      "NKCGateway.nmconnection" = {
        file = ./. + "/NKCGateway.nmconnection.age";
      };
    };
  };
}
