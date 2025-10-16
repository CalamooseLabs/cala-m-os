{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:06:00.4"; # Bus 05 & 06 for USB Controller (under 2.5gig nic)
    }
  ];
}
