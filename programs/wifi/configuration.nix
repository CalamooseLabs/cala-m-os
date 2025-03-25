{config, ...}: {
  sops = {
    secrets = {
      CalamooseWiFi_Password = {
        sopsFile = ./secrets/CalamooseWiFi.json;
        format = "json";
        restartUnits = ["NetworkManager.service"];
      };
    };

    templates = {
      "Calamoose WiFi.nmconnection" = {
        content = ''
          [connection]
          id=Calamoose WiFi
          uuid=48bbbcb0-fc45-47b8-8768-c26dd385da51
          type=wifi
          interface-name=wlp166s0

          [wifi]
          mode=infrastructure
          ssid=Calamoose WiFi

          [wifi-security]
          auth-alg=open
          key-mgmt=wpa-psk
          psk=${config.sops.placeholder.CalamooseWiFi_Password}

          [ipv4]
          method=auto

          [ipv6]
          addr-gen-mode=default
          method=auto

          [proxy]
        '';
        path = "/etc/NetworkManager/system-connections/Calamoose WiFi.nmconnection";
      };
    };
  };
}
