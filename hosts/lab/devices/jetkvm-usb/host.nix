{...}: {
  services.udev.extraRules = ''
    # JetKVM USB Emulation
    SUBSYSTEM=="usb", ATTR{idVendor}=="1d6b", ATTR{idProduct}=="0104", GROUP="kvm"
  '';
}
