{config, ...}: {
  networking.firewall.checkReversePath = "loose";

  sops = {
    templates = {
      "CasaMosVPN.nmconnection" = {
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
