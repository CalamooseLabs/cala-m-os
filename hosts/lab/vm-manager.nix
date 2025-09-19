{
  vms,
  networkInterface,
}: {
  inputs,
  self,
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
      flake = self;
      updateFlake = "git+file:///etc/nixos";
      autostart = true;

      # Pass specialArgs to the VM's nixosConfiguration
      specialArgs = {
        inherit networkInterface;
        vmName = name;
        vmConfig = vm;
        vmDeviceFiles = map (device: getDeviceFiles device "guest.nix") vm.devices;
      };
    })
    vms;
in {
  imports = [inputs.microvm.nixosModules.host] ++ host_files;

  microvm.vms = vm_configs;
}
