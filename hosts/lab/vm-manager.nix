{
  vms,
  networkInterface,
}: {
  inputs,
  # self,
  cala-m-os,
  ...
}: let
  device_path = ./devices;

  getDeviceFiles = device: filename: import (device_path + "/${device}/${filename}");

  allDevices = builtins.concatLists (builtins.attrValues (
    builtins.mapAttrs (name: vm: vm.devices) vms
  ));

  uniqueDevices = builtins.attrNames (
    builtins.listToAttrs (map (d: {
        name = d;
        value = true;
      })
      allDevices)
  );

  host_files = map (device: getDeviceFiles device "host.nix") uniqueDevices;

  vm_configs =
    builtins.mapAttrs (name: vm: {
      # flake = self;
      # updateFlake = "git+file:///etc/nixos";
      # autostart = true;

      config = import ../${name}/configuration.nix;
      # Pass specialArgs to the VM's nixosConfiguration
      specialArgs = {
        inherit inputs cala-m-os;
        vmName = name;
        vmConfig = vm;
        vmDeviceFiles = map (device: getDeviceFiles device "guest.nix") vm.devices;
        vmBridge = networkInterface;
      };
    })
    vms;
in {
  imports = [inputs.microvm.nixosModules.host] ++ host_files;

  microvm.vms = vm_configs;
}
