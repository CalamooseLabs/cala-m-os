{...}: {
  imports = [../../../../machines/modules/intel-gpu/configuration.nix];

  microvm.devices = [
    {
      bus = "pci";
      path = "0000:44:00.0"; # Arc A310
    }
    {
      bus = "pci";
      path = "0000:45:00.0"; # Arc A310 Audio
    }
  ];
}
