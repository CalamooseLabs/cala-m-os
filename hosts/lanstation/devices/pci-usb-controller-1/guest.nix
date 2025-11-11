{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:46:00.0";
    } # USB Controller
  ];
}
