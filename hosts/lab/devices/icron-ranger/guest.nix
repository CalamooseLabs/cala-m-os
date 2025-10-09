{...}: {
  microvm.devices = [
    {
      bus = "usb";
      path = "vendorid=0x04b4,productid=0x6506"; # Icron Ranger Cypress
    }
    {
      bus = "usb";
      path = "vendorid=0x13d3,productid=0x3602"; # Icron Ranger IMC
    }
  ];
}
