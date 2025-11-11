{...}: {
  imports = [../../../../machines/modules/nvidia-gpu/configuration.nix];

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:01:00.0"; # RTX 5090
    }
    {
      bus = "pci";
      path = "0000:01:00.1"; # RTX 5090 Audio
    }
  ];
}
