{config, ...}: {
  imports = [
    ./secrets
  ];

  networking.firewall.checkReversePath = "loose";

  environment.etc = {
    "NetworkManager/system-connections/CasaMos VPN.nmconnection" = {
      source = config.age.secrets."CasaMosVPN.nmconnection".path;
    };
    "NetworkManager/system-connections/NKC Gateway VPN.nmconnection" = {
      source = config.age.secrets."NKCGateway.nmconnection".path;
    };
  };
}
