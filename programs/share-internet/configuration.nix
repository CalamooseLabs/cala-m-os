{...}: {
  # Enable nftables service
  networking.nftables.enable = true;

  networking.firewall.allowedUDPPorts = [
    53
    67
    68
  ];

  # Basic dnsmasq configuration
  services.dnsmasq.enable = true;
}
