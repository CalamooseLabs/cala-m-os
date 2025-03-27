{...}: {
  # Enable nftables service
  networking.nftables.enable = true;

  # Allow forwarding in the firewall
  networking.firewall.allowedUDPPorts = [53 67 68 5353]; # DNS and DHCP ports

  # Enable IP forwarding at the system level
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Basic dnsmasq configuration
  # services.dnsmasq.enable = true;
}
