{pkgs, ...}: {
  # Driver override service
  systemd.services.vfio-usb-bind = {
    description = "Bind USB controller to vfio-pci";
    wantedBy = ["multi-user.target"];
    after = ["systemd-modules-load.service"];
    before = ["display-manager.service"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${pkgs.bash}/bin/bash -c 'echo 0000:c1:00.4 > /sys/bus/pci/devices/0000:c1:00.4/driver/unbind 2>/dev/null || true'"
        "${pkgs.bash}/bin/bash -c 'echo vfio-pci > /sys/bus/pci/devices/0000:c1:00.4/driver_override'"
        "${pkgs.bash}/bin/bash -c 'echo 0000:c1:00.4 > /sys/bus/pci/drivers/vfio-pci/bind'"
      ];
    };
  };
}
