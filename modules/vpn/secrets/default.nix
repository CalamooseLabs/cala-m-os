# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
{...}: {
  calamoose.secrets = {
    "CasaMosVPN.nmconnection" = {
      agenixFile = ./CasaMosVPN.nmconnection.age;
      reference = "pass://REPLACE_ME/CasaMosVPN.nmconnection";
    };
    "NKCGateway.nmconnection" = {
      agenixFile = ./NKCGateway.nmconnection.age;
      reference = "pass://REPLACE_ME/NKCGateway.nmconnection";
    };
  };
}
