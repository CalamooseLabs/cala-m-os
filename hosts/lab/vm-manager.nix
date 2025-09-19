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
      config = {
        imports = [../${name}/configuration.nix] ++ (map (device: getDeviceFiles device "guest.nix") vm.devices);

        microvm = {
          interfaces = [
            {
              type = "macvtap";
              id = "vm-${name}";
              mac = "02:00:00:00:00:${vm.macID}";
              macvtap = {
                mode = "bridge";
                link = networkInterface;
              };
            }
            # {
            #   type = "tap";
            #   id = "vm-${name}--to-host";
            #   mac = "02:00:00:00:01:${vm.macID}";
            # }
          ];

          volumes = [
            {
              image = "${name}-vm.img";
              mountPoint = "/";
              size = vm.storage * 1024;
            }
          ];
        };

        networking.interfaces.eth0.useDHCP = true;
      };

      specialArgs = {
        inherit inputs cala-m-os;
      };
    })
    vms;
in {
  imports = [inputs.microvm.nixosModules.host] ++ host_files;

  microvm.vms = vm_configs;
}
