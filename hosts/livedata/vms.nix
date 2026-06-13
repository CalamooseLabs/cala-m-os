{...}: let
  vms = {
    "openreturn" = {
      devices = [];
      storage = 600; # GBs
      shares = [];
      hostOverride = "openreturn";
      # Static: settings.nix cala-m-os.ip has no key for this VM and targets the
      # wrong 10.10.10.0/24 subnet, so without these the guest silently DHCPs.
      ipOverride = "10.1.10.41";
      gatewayOverride = "10.1.10.1";
      dns = ["10.1.10.1"];
    };
    "quorumcall" = {
      devices = [];
      storage = 100;
      shares = [];
      hostOverride = "quorumcall";
      ipOverride = "10.1.10.42";
      gatewayOverride = "10.1.10.1";
      dns = ["10.1.10.1"];
    };
  };

  bridgeInterface = "enp88s0";
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
