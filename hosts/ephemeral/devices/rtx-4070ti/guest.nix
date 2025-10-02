{...}: {
  imports = [../../../../machines/modules/nvidia-gpu/configuration.nix];

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:06:00.0"; # RTX 4070 Ti Audio
    }
    {
      bus = "pci";
      path = "0000:06:00.1"; # RTX 4070 Ti Audio
    }
  ];
}
