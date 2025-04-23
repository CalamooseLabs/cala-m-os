{config, ...}: {
  imports = [
    ./secrets
  ];

  environment.etc = {
    "NetworkManager/system-connections/Calamoose WiFi.nmconnection" = {
      source = config.age.secrets."CalamooseWiFi.nmconnection".path;
    };
  };
  # path = "/etc/NetworkManager/system-connections/Calamoose WiFi.nmconnection";
}
