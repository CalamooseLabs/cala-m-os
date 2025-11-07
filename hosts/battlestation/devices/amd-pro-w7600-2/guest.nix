{...}: {
  imports = [../../../../machines/modules/amd-gpu/configuration.nix];

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:85:00.0"; # Pro W7600
    }
    {
      bus = "pci";
      path = "0000:85:00.1"; # Pro W7600 Audio
    }
  ];
}
