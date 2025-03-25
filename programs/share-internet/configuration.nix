{...}: {
  # Enable nftables service
  networking.nftables.enable = true;

  # Basic dnsmasq configuration
  services.dnsmasq.enable = true;
}
