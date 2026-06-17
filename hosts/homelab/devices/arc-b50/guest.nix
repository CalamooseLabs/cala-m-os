{...}: {
  imports = [../../../../machines/modules/intel-gpu/configuration.nix];

  # TODO: confirm the Arc B50 PCIe addresses on the host (`lspci -nn | grep -i vga`)
  # — the values below are carried over from the A310 and need verifying.
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:03:00.0"; # Arc B50
    }
  ];
}
