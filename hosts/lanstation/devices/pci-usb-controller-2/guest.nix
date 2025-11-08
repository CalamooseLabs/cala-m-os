{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:89:00.0";
    } # USB Controller
  ];
}
