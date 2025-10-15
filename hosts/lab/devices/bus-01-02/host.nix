{...}: {
  services.udev.extraRules = ''
    # Anker HUB
    SUBSYSTEM=="usb", ATTR{idVendor}=="05e3", ATTR{idProduct}=="0610", GROUP="kvm", MODE="0660"
  '';
}
