{...}: let
  vms = {
    "openreturn" = {
      devices = [];
      storage = 600; # GBs
      shares = [];
      ipOverride = "10.1.10.41";
    };
    "quorumcall" = {
      devices = [];
      storage = 100;
      shares = [];
      ipOverride = "10.1.10.42";
    };
  };

  bridgeInterface = "enp88s0";
in {
  imports = [
    (import ../../services/vm-manager/default.nix {
      device_path = ./devices;
      vms = vms;
      networkInterface = bridgeInterface;
    })
  ];
}
