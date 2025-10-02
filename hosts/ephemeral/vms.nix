{...}: let
  vms = {
    "travel" = {
      devices = ["rtx-4070ti"];
      storage = 100; # GBs
      macID = "02";
      shares = [];
    };
  };

  bridgeInterface = "enp4s0";
in {
  imports = [
    (import ../../services/vm-manager/default.nix {
      device_path = ./devices;
      vms = vms;
      networkInterface = bridgeInterface;
    })
  ];
}
