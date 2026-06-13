# Resolves the per-device host.nix passthrough modules for a set of VMs.
#
# These must be top-level host imports (they configure the host for device
# passthrough), and NixOS forbids `imports` from depending on `config`, so the
# VM host computes them statically from its raw `vms` set and `devicePath`
# rather than going through the services.cala-vm-manager option.
{
  devicePath,
  vms,
}: let
  allDevices = builtins.concatLists (map (vm: vm.devices or []) (builtins.attrValues vms));
  uniqueDevices = builtins.attrNames (builtins.listToAttrs (map (d: {
      name = d;
      value = true;
    })
    allDevices));
in
  map (device: devicePath + "/${device}/host.nix") uniqueDevices
