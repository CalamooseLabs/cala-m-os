{...}: {
  imports = [../../../../machines/modules/nvidia-gpu/configuration.nix];

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:41:00.0"; # Arc A310
    }
  ];
}
