{inputs, ...}: {
  # `bridge-internet` (antlers): share the host's internet over an ethernet NIC
  # (dnsmasq DHCP + nftables NAT). Its dnsmasq/nftables deps are baked into the
  # wrapper, so the old ~/.local/bin + home.packages plumbing is gone. The
  # system-level prerequisites (nftables, firewall ports, ip_forward) stay in
  # ./configuration.nix.
  imports = [inputs.antlers.homeManagerModules.antlers-scripts];
  programs.antlers-scripts = {
    enable = true;
    bridge-internet.enable = true;
  };
}
