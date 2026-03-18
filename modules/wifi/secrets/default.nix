{...}: {
  age = {
    secrets = {
      "CalamooseWiFi.nmconnection" = {
        file = ./. + "/CalamooseWiFi.nmconnection.age";
      };
      "CalamooseLabs.nmconnection" = {
        file = ./. + "/CalamooseLabs.nmconnection.age";
      };
    };
  };
}
