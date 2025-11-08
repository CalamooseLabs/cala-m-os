{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:8b:00.0";
    } # USB Controller
  ];
}
