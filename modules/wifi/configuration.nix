{config, lib, ...}: {
  imports = [./secrets];

  environment.etc = lib.mkIf config.calamoose.enableSecrets {
    "NetworkManager/system-connections/Calamoose WiFi.nmconnection" = {
      source = config.age.secrets."CalamooseWiFi.nmconnection".path;
    };
    "NetworkManager/system-connections/Calamoose Labs.nmconnection" = {
      source = config.age.secrets."CalamooseLabs.nmconnection".path;
    };
    "NetworkManager/system-connections/NKC WiFi.nmconnection" = {
      source = config.age.secrets."NKCWiFi.nmconnection".path;
    };
    "NetworkManager/system-connections/theisenair.nmconnection" = {
      source = config.age.secrets."theisenair.nmconnection".path;
    };
    "NetworkManager/system-connections/NETGEAR43.nmconnection" = {
      source = config.age.secrets."NETGEAR43.nmconnection".path;
    };
  };
}
