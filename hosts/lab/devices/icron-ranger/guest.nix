{...}: {
  microvm.devices = [
    {
      bus = "usb";
      path = "vendorid=0x04b4,productid=0x6506"; # Icron Ranger Device
    }
    {
      bus = "usb";
      path = "vendorid=0x046d,productid=0xc52b"; # Logitech
    }
    {
      bus = "usb";
      path = "vendorid=0x2dc8,productid=0x3109"; # 8 Bitdo Pro 3
    }
  ];
}
