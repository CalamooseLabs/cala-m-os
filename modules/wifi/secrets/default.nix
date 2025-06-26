{...}: {
  age = {
    secrets = {
      "CalamooseWiFi.nmconnection" = {
        file = ./. + "/CalamooseWiFi.nmconnection.age";
      };
    };
    identityPaths = [
      "/etc/nixos/modules/agenix/identities/yubi.key"
    ];
  };
}
