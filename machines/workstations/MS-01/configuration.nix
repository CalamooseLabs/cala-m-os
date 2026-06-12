##################################
#                                #
#      Minisforum MS-01          #
#                                #
##################################
{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # MS-01 i226-V (igc) link stability: the 2.5GbE ports drop/degrade after
  # uptime with PCIe ASPM + EEE enabled ("works at boot, then degrades").
  # pcie_port_pm=off is narrower than pcie_aspm=off (avoids AER noise); EEE
  # has no igc module param (only `debug`), so it must be cleared via ethtool.
  boot.kernelParams = ["pcie_port_pm=off"];

  systemd.services.nic-eee-off = {
    description = "Disable EEE on enp88s0 (i226-V link stability)";
    after = ["sys-subsystem-net-devices-enp88s0.device"];
    bindsTo = ["sys-subsystem-net-devices-enp88s0.device"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.ethtool}/bin/ethtool --set-eee enp88s0 eee off";
    };
  };
}
