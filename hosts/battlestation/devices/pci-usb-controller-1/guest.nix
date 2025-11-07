{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:88:00.0";
    } # USB Controller
  ];
}
