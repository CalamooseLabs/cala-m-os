{...}: {
  microvm.devices = [
    {
      bus = "usb";
      path = "vendorid=0x05e3,productid=0x0610"; # Ankey 3.0 HUB
    }
  ];
}
