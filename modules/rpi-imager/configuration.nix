{...}: {
  services.udev.extraRules = ''
    # Raspberry Pi usbboot
    SUBSYSTEM=="usb", ATTR{idVendor}=="0a5c", ATTR{idProduct}=="2763", GROUP="plugdev", MODE="0664"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0a5c", ATTR{idProduct}=="2764", GROUP="plugdev", MODE="0664"
  '';
}
