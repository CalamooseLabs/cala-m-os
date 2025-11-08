{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:8a:00.0";
    } # USB Controller
  ];
}
