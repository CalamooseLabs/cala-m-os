{...}: {
  services.udev.extraRules = ''
    # Icron Ranger
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b4", ATTR{idProduct}=="6506", GROUP="kvm"
    # Unifying Logitech
    SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c52b", GROUP="kvm"
  '';
}
