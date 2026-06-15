{cala-m-os, ...}: let
  vms = {
    "lanstation-2" = {
      autostart = false;
      hostOverride = "lanstation-vm";
      ipOverride = "${cala-m-os.ip.lab.lanstation-2}";
      devices = ["amd-9060-xt" "pci-usb-controller-1" "pci-usb-controller-2"];
      storage = 200; # GBs
      shareStore = false;
      storeOnDisk = true;
      # dns = ["${cala-m-os.ip.lab.vault}"];
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
      ipOverride = "${cala-m-os.ip.lab.lanstation-3}";
      devices = ["amd-pro-w7600-1" "pci-usb-controller-3"];
      storage = 200; # GBs
      shareStore = false;
      storeOnDisk = true;
      # dns = ["${cala-m-os.ip.lab.vault}"];
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
      ipOverride = "${cala-m-os.ip.lab.lanstation-4}";
      devices = ["amd-pro-w7600-2" "pci-usb-controller-4"];
      storage = 200; # GBs
      shareStore = false;
      storeOnDisk = true;
      # dns = ["${cala-m-os.ip.lab.vault}"];
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
  imports =
    [../../services/vm-manager]
    ++ (import ../../services/vm-manager/host-imports.nix {
      devicePath = ./devices;
      inherit vms;
    });

  services.cala-vm-manager = {
    enable = true;
    devicePath = ./devices;
    networkInterface = bridgeInterface;
    inherit vms;
  };
}
