{...}: {
  microvm.devices = [
    {
      bus = "usb";
      path = "vendorid=0x07ca,productid=0x0575"; # AverMedia Capture Card 4K 2.1
    }
  ];
}
