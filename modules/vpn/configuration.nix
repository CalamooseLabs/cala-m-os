{config, lib, enable_secrets ? true, ...}: {
  imports = [./secrets];

  networking.firewall.checkReversePath = "loose";

  environment.etc = lib.mkIf enable_secrets {
    "NetworkManager/system-connections/CasaMos VPN.nmconnection" = {
      source = config.age.secrets."CasaMosVPN.nmconnection".path;
    };
    "NetworkManager/system-connections/NKC Gateway VPN.nmconnection" = {
      source = config.age.secrets."NKCGateway.nmconnection".path;
    };
  };
  systemd.services.agenix-rerun.before = lib.mkIf enable_secrets ["NetworkManager.service"];
}
