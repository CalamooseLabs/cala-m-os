{config, ...}: {
  networking.networkmanager.dns = "systemd-resolved";
  services.resolved.enable = true;

  networking.wg-quick.interfaces = {
    wg0 = {
      address = ["10.0.0.12/32"];
      dns = ["10.0.0.10"];
      privateKeyFile = config.sops.secrets.CasaMosVPN_PrivateKey.path;

      peers = [
        {
          publicKey = "TYTGNq3NY5etwSjJtXdAYWAClFjCzcdYyQBSBmZZjlU=";
          allowedIPs = ["0.0.0.0/0"];
          endpoint = "152.117.65.133:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
