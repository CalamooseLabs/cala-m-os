{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:47:00.0";
    } # USB Controller
  ];
}
