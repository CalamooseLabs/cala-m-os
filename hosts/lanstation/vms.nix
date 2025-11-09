{cala-m-os, ...}: let
  vms = {
    "lanstation-2" = {
      autostart = false;
      hostOverride = "lanstation-vm";
      ipOverride = "${cala-m-os.ip.lanstation-2}";
      devices = ["amd-9060-xt" "pci-usb-controller-1" "pci-usb-controller-2"];
      storage = 200; # GBs
      shareStore = false;
      storeOnDisk = true;
      # dns = ["${cala-m-os.ip.vault}"];
      shares = [
        {
          proto = "virtiofs";
          tag = "games";
          source = "/vm-data";
          mountPoint = "/mnt/games";
        }
      ];
    };
    "lanstation-3" = {
      autostart = false;
      hostOverride = "lanstation-vm";
      ipOverride = "${cala-m-os.ip.lanstation-3}";
      devices = ["amd-pro-w7600-1" "pci-usb-controller-3"];
      storage = 200; # GBs
      shareStore = false;
      storeOnDisk = true;
      # dns = ["${cala-m-os.ip.vault}"];
      shares = [
        {
          proto = "virtiofs";
          tag = "games";
          source = "/vm-data";
          mountPoint = "/mnt/games";
        }
      ];
    };
    "lanstation-4" = {
      autostart = false;
      hostOverride = "lanstation-vm";
      ipOverride = "${cala-m-os.ip.lanstation-4}";
      devices = ["amd-pro-w7600-2" "pci-usb-controller-4"];
      storage = 200; # GBs
      shareStore = false;
      storeOnDisk = true;
      # dns = ["${cala-m-os.ip.vault}"];
      shares = [
        {
          proto = "virtiofs";
          tag = "games";
          source = "/vm-data";
          mountPoint = "/mnt/games";
        }
      ];
    };
  };

  bridgeInterface = "eno2";
in {
  imports = [
    (import ../../services/vm-manager/default.nix {
      device_path = ./devices;
      vms = vms;
      networkInterface = bridgeInterface;
    })
  ];
}
