{
  config,
  lib,
  ...
}: {
  imports = [./secrets];

  networking.firewall.checkReversePath = "loose";

  environment.etc = lib.mkIf config.calamoose.enableSecrets {
    "NetworkManager/system-connections/CasaMos VPN.nmconnection" = {
      source = config.age.secrets."CasaMosVPN.nmconnection".path;
    };
    "NetworkManager/system-connections/NKC Gateway VPN.nmconnection" = {
      source = config.age.secrets."NKCGateway.nmconnection".path;
    };
  };
  # NOTE: this previously set `systemd.services.agenix-rerun.before = ["NetworkManager.service"]`,
  # but no `agenix-rerun` service is defined anywhere (its definition in modules/agenix-boot is
  # fully commented out), so that line only synthesised an ExecStart-less phantom unit that ordered
  # nothing. agenix installs these .nmconnection secrets during activation, before systemd starts
  # NetworkManager, so no extra ordering is required. If Yubikey-at-boot re-decryption is ever
  # needed, implement a real agenix-rerun service in modules/agenix-boot and order against it here.
}
