{...}: {
  networking.firewall.allowedUDPPorts = [51820];

  # Remove the incompatible iptables commands
  networking.firewall.extraCommands = "";
  networking.firewall.extraStopCommands = "";

  # Enable nftables
  networking.nftables.enable = true;

  networking.nftables.ruleset = ''
    # WireGuard-specific rules to bypass reverse path filtering
    table inet filter {
      chain nixos-fw-rpfilter {
        udp sport 51820 return
        udp dport 51820 return
      }
    }
  '';
}
