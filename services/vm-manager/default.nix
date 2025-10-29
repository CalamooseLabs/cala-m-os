{
  device_path,
  vms,
  networkInterface,
}: {
  lib,
  inputs,
  initialInstallMode,
  cala-m-os,
  ...
}: let
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
        imports = [../../hosts/${name}/configuration.nix] ++ (map (device: getDeviceFiles device "guest.nix") vm.devices);

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
          ];

          volumes = [
            {
              image = "${name}-vm.img";
              mountPoint = "/";
              size = vm.storage * 1024;
            }
          ];

          shares =
            [
              {
                proto = "virtiofs";
                tag = "agenix";
                source = "/run/agenix";
                mountPoint = "/run/agenix";
              }
            ]
            ++ vm.shares
            ++ lib.optionals (
              if vm ? shareStore
              then vm.shareStore
              else true
            ) [
              {
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                tag = "ro-store";
                proto = "virtiofs";
              }
            ];
        };

        networking = {
          useNetworkd = true;
          useDHCP = false;
        };

        systemd.network.networks."10-macvtap" = {
          matchConfig.Name = "enp0s6";

          address = [
            "${vm.ip}/${toString 26}"
          ];

          routes = [
            {
              Destination = "0.0.0.0/0";
              Gateway = cala-m-os.ip.gateway;
              GatewayOnLink = true;
            }
          ];
        };
      };

      specialArgs = {
        inherit inputs cala-m-os initialInstallMode;
      };
    })
    vms;
in {
  imports = [inputs.microvm.nixosModules.host] ++ host_files;

  microvm.vms = vm_configs;
}
