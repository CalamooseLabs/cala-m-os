{...}: {
  microvm.devices = [
    {
      bus = "usb";
      path = "vendorid=0x1d6b,productid=0x0104"; # JetKVM USB Emulation
    }
  ];
}
