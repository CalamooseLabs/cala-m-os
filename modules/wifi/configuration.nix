{
  config,
  lib,
  ...
}: {
  imports = [./secrets];

  environment.etc = lib.mkIf config.calamoose._secretsEnabled {
    "NetworkManager/system-connections/Calamoose WiFi.nmconnection" = {
      source = config.calamoose.secrets."CalamooseWiFi.nmconnection".path;
    };
    "NetworkManager/system-connections/Calamoose Labs.nmconnection" = {
      source = config.calamoose.secrets."CalamooseLabs.nmconnection".path;
    };
    "NetworkManager/system-connections/NKC WiFi.nmconnection" = {
      source = config.calamoose.secrets."NKCWiFi.nmconnection".path;
    };
    "NetworkManager/system-connections/theisenair.nmconnection" = {
      source = config.calamoose.secrets."theisenair.nmconnection".path;
    };
    "NetworkManager/system-connections/NETGEAR43.nmconnection" = {
      source = config.calamoose.secrets."NETGEAR43.nmconnection".path;
    };
  };
}
