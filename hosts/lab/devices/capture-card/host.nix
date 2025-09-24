{...}: {
  services.udev.extraRules = ''
    # AverMedia Live Gamer 4K 2.1 Capture Card
    SUBSYSTEM=="usb", ATTR{idVendor}=="07ca", ATTR{idProduct}=="0575", GROUP="kvm"
  '';
}
