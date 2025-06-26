{...}: {
  age = {
    secrets = {
      "CasaMosVPN.nmconnection" = {
        file = ./. + "/CasaMosVPN.nmconnection.age";
      };
      "NKCGateway.nmconnection" = {
        file = ./. + "/NKCGateway.nmconnection.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
