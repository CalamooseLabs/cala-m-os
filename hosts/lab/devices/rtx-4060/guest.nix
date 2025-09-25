{...}: {
  imports = [../../../../machines/modules/nvidia-gpu/configuration.nix];

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:41:00.0"; # RTX 4060 Audio
    }
    {
      bus = "pci";
      path = "0000:41:00.1"; # RTX 4060 Audio
    }
  ];
}
