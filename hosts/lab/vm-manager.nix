{vms}: {
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
      imports = [self.nixosConfiguration.${name}.config] ++ (map (device: getDeviceFiles device "guest.nix") vm.devices);
      microvm = {
        interfaces = [
          {
            type = "tap";
            id = "vm-${name}";
            mac = vm.mac;
          }
        ];
        volumes = [
          {
            image = "${name}-vm.img";
            mountPoint = "/";
            size = vm.storage * 1024;
          }
        ];
      };
    })
    vms;
in {
  imports = [inputs.microvm.nixosModules.host] ++ host_files;

  microvm.vms = vm_configs;
}
