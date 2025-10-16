{...}: {
  microvm.devices = [
    # Group 29 - all devices by PCI address
    {
      bus = "pci";
      path = "0000:00:07.0";
    } # Host Bridge (by address, not ID)
    {
      bus = "pci";
      path = "0000:00:07.1";
    } # PCI Bridge (by address, not ID)
    {
      bus = "pci";
      path = "0000:06:00.0";
    } # Non-Essential (bound via ID)
    {
      bus = "pci";
      path = "0000:06:00.4";
    } # USB Controller (bound via ID) (under 2.5 gig nic)
    {
      bus = "pci";
      path = "0000:06:00.5";
    } # Encryption (bound via ID)
    {
      bus = "pci";
      path = "0000:06:00.7";
    } # Audio (bound via ID)
  ];
}
