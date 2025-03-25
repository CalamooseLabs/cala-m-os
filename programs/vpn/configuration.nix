{config, ...}: {
  networking.firewall.checkReversePath = "loose";

  sops = {
    secrets = {
      CasaMosVPN_PrivateKey = {
        sopsFile = ./secrets/CasaMosVPN.json;
        format = "json";
        restartUnits = ["NetworkManager.service"];
      };
      CasaMosVPN_PublicKey = {
        sopsFile = ./secrets/CasaMosVPN.json;
        format = "json";
        restartUnits = ["NetworkManager.service"];
      };
      CasaMosVPN_Address = {
        sopsFile = ./secrets/CasaMosVPN.json;
        format = "json";
        restartUnits = ["NetworkManager.service"];
      };
      CasaMosVPN_DNS = {
        sopsFile = ./secrets/CasaMosVPN.json;
        format = "json";
        restartUnits = ["NetworkManager.service"];
      };
      CasaMosVPN_AllowedIPS = {
        sopsFile = ./secrets/CasaMosVPN.json;
        format = "json";
        restartUnits = ["NetworkManager.service"];
      };
      CasaMosVPN_Endpoint = {
        sopsFile = ./secrets/CasaMosVPN.json;
        format = "json";
        restartUnits = ["NetworkManager.service"];
      };
    };

    templates = {
      "CasaMos VPN.nmconnection" = {
        content = ''
          [connection]
          id=CasaMos VPN
          uuid=518f99f8-a3d4-4baf-b746-3fc4e0c40a40
          type=wireguard
          interface-name=wg0
          autoconnect=false

          [wireguard]
          private-key=${config.sops.placeholder.CasaMosVPN_PrivateKey}

          [wireguard-peer.${config.sops.placeholder.CasaMosVPN_PublicKey}]
          endpoint=${config.sops.placeholder.CasaMosVPN_Endpoint}
          allowed-ips=${config.sops.placeholder.CasaMosVPN_AllowedIPS}
          persistent-keepalive=25

          [ipv4]
          method=manual
          address1=${config.sops.placeholder.CasaMosVPN_Address}
          dns=${config.sops.placeholder.CasaMosVPN_DNS}

          [ipv6]
          method=disabled
        '';
        path = "/etc/NetworkManager/system-connections/CasaMos VPN.nmconnection";
      };
    };
  };
}
