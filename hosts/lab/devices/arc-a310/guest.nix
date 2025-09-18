{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:44:00.0"; # Arc A310
    }
  ];
}
