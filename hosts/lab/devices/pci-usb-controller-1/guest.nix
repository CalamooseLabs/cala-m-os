{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:85:00.0";
    } # USB Controller
  ];
}
