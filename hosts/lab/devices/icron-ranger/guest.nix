{...}: {
  microvm.devices = [
    {
      bus = "usb";
      path = "vendorid=0x04b4,productid=0x6506"; # Icron Ranger Device
    }
  ];
}
