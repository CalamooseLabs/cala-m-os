# Backend-neutral secret declarations (see modules/secrets/configuration.nix).
# These are whole-file secrets (NetworkManager .nmconnection files); for the online
# backend, store each file's contents in a Proton Pass item and point the reference
# (optionally with a /field) at it.
{...}: {
  calamoose.secrets = {
    "CalamooseWiFi.nmconnection" = {
      agenixFile = ./CalamooseWiFi.nmconnection.age;
      reference = "pass://REPLACE_ME/CalamooseWiFi.nmconnection";
    };
    "CalamooseLabs.nmconnection" = {
      agenixFile = ./CalamooseLabs.nmconnection.age;
      reference = "pass://REPLACE_ME/CalamooseLabs.nmconnection";
    };
    "NKCWiFi.nmconnection" = {
      agenixFile = ./NKCWiFi.nmconnection.age;
      reference = "pass://REPLACE_ME/NKCWiFi.nmconnection";
    };
    "theisenair.nmconnection" = {
      agenixFile = ./theisenair.nmconnection.age;
      reference = "pass://REPLACE_ME/theisenair.nmconnection";
    };
    "NETGEAR43.nmconnection" = {
      agenixFile = ./NETGEAR43.nmconnection.age;
      reference = "pass://REPLACE_ME/NETGEAR43.nmconnection";
    };
  };
}
