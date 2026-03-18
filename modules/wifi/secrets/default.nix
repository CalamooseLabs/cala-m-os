{...}: {
  age = {
    secrets = {
      "CalamooseWiFi.nmconnection" = {
        file = ./. + "/CalamooseWiFi.nmconnection.age";
      };
      "CalamooseLabs.nmconnection" = {
        file = ./. + "/CalamooseLabs.nmconnection.age";
      };
      "NKCWiFi.nmconnection" = {
        file = ./. + "/NKCWiFi.nmconnection.age";
      };
      "theisenair.nmconnection" = {
        file = ./. + "/theisenair.nmconnection.age";
      };
      "NETGEAR43.nmconnection" = {
        file = ./. + "/NETGEAR43.nmconnection.age";
      };
    };
  };
}
