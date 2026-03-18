{config, ...}: {
  imports = [
    ./secrets
  ];

  environment.etc = {
    "NetworkManager/system-connections/Calamoose WiFi.nmconnection" = {
      source = config.age.secrets."CalamooseWiFi.nmconnection".path;
    };
    "NetworkManager/system-connections/Calamoose Labs.nmconnection" = {
      source = config.age.secrets."CalamooseLabs.nmconnection".path;
    };
  };
}
