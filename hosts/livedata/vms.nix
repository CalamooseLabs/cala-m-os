{...}: let
  vms = {
    "openreturn" = {
      devices = [];
      storage = 600; # GBs
      shares = [];
      hostOverride = "openreturn";
    };
    "quorumcall" = {
      devices = [];
      storage = 100;
      shares = [];
      hostOverride = "quorumcall";
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
