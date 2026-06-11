{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:48:00.0";
    } # USB Controller
  ];
}
