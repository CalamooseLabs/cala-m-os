{...}: let
  vms = {
    "openreturn" = {
      devices = [];
      storage = 600; # GBs
      shares = [];
      hostOverride = "openreturn";
      ipOverride = "10.1.10.41";
      gatewayOverride = "10.1.10.1";
    };
    "quorumcall" = {
      devices = [];
      storage = 100;
      shares = [];
      hostOverride = "quorumcall";
      ipOverride = "10.1.10.42";
      gatewayOverride = "10.1.10.1";
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
