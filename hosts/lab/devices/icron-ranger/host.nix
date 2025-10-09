{...}: {
  services.udev.extraRules = ''
    # Icron Ranger
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b4", ATTR{idProduct}=="6506", GROUP="kvm"
    SUBSYSTEM=="usb", ATTR{idVendor}=="13d3", ATTR{idProduct}=="3602", GROUP="kvm"
  '';
}
