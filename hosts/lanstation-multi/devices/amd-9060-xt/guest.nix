{...}: {
  imports = [../../../../machines/modules/amd-gpu/configuration.nix];

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:43:00.0"; # RX 9060 XT
    }
    {
      bus = "pci";
      path = "0000:43:00.1"; # RX 9060 XT Audio
    }
  ];
}
