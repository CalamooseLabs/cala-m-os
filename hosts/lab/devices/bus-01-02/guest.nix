{...}: {
  microvm.devices = [
    {
      bus = "pci";
      path = "0000:c1:00.4"; # Bus 01 & 02 for USB Controller (under 10gig nic)
    }
  ];
}
