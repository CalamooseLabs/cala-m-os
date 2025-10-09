{...}: {
  microvm.devices = [
    {
      bus = "usb";
      path = "vendorid=0x04b4,productid=0x6506"; # Icron Ranger Cypress
    }
    {
      bus = "usb";
      path = "vendorid=0x1a40,productid=0x0101"; # Icron Ranger Cypress
    }
    # {
    #   bus = "usb";
    #   path = "vendorid=0x046d,productid=0xc52b"; # Logitech
    # }
  ];
}
