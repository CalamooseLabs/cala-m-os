{...}: {
  microvm.devices = [
    # Group 6 - all devices by PCI address
    {
      bus = "pci";
      path = "0000:c1:00.0";
    } # Non-Essential (bound via ID)
    {
      bus = "pci";
      path = "0000:c1:00.4";
    } # USB Controller (bound via ID) (Under 10gig nic)
  ];
}
