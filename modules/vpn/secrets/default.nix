{lib, enable_secrets ? true, ...}: {
  age = lib.mkIf enable_secrets {
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
