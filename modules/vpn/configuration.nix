{
  config,
  lib,
  ...
}: {
  imports = [./secrets];

  networking.firewall.checkReversePath = "loose";

  environment.etc = lib.mkIf config.calamoose._secretsEnabled {
    "NetworkManager/system-connections/CasaMos VPN.nmconnection" = {
      source = config.calamoose.secrets."CasaMosVPN.nmconnection".path;
    };
    "NetworkManager/system-connections/NKC Gateway VPN.nmconnection" = {
      source = config.calamoose.secrets."NKCGateway.nmconnection".path;
    };
  };
  # agenix-specific ordering (no agenix-rerun unit exists under the online backend).
  systemd.services.agenix-rerun.before = lib.mkIf (config.calamoose._secretsBackend == "agenix") ["NetworkManager.service"];
}
