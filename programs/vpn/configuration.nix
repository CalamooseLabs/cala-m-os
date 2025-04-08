{config, ...}: {
  imports = [
    ./secrets
  ];

  networking.firewall.checkReversePath = "loose";

  environment.etc = {
    "NetworkManager/system-connections/CasaMos VPN.nmconnection" = {
      source = config.age.secrets."CasaMosVPN.nmconnection".path;
    };
  };
}
