{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:49:00.0";
    } # USB Controller
  ];
}
