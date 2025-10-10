{...}: {
  services.udev.extraRules = ''
    # Icron Ranger
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b4", ATTR{idProduct}=="6506", GROUP="kvm"
    SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c52b", GROUP="kvm"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", ATTR{idProduct}=="3109", GROUP="kvm"
  '';
}
