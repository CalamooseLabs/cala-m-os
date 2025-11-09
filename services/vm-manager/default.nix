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
      autostart = vm.autostart or true;
      config = {
        imports = [../../hosts/${vm.hostOverride or name}/configuration.nix] ++ (map (device: getDeviceFiles device "guest.nix") vm.devices);

        microvm = {
          interfaces = [
            {
              type = "macvtap";
              id = "vm-${name}";
              mac = "02:00:00:00:00:${lib.last (lib.splitString "." cala-m-os.ip.${name})}";
              macvtap = {
                mode = "bridge";
                link = networkInterface;
              };
            }
          ];

          volumes =
            [
              {
                image = "${name}-vm.img";
                mountPoint = "/";
                size = vm.storage * 1024;
              }
            ]
            ++ lib.optionals (
              if vm ? storeOnDisk
              then vm.storeOnDisk
              else false
            ) [
              {
                image = "nix-store-${name}.img";
                mountPoint = "/nix/.rw-store";
                size = 51200; # 50GB
                autoCreate = true;
                fsType = "ext4";
              }
            ];

          shares =
            [
              {
                proto = "virtiofs";
                tag = "agenix";
                source = "/run/agenix";
                mountPoint = "/run/hostsecrets";
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

        systemd.network.networks = {
          "${cala-m-os.networking.network-name}" = {
            matchConfig.MACAddress = "02:00:00:00:00:${lib.last (lib.splitString "." (vm.ipOverride or cala-m-os.ip.${name}))}";

            address = [
              "${vm.ipOverride or cala-m-os.ip.${name}}/${cala-m-os.networking.prefixLength}"
            ];

            routes = [
              {
                Destination = "0.0.0.0/0";
                Gateway = cala-m-os.ip.gateway;
                GatewayOnLink = true;
              }
            ];

            networkConfig = {
              DNS =
                if vm ? dns
                then vm.dns
                else ["${cala-m-os.ip.gateway}"];
            };
          };

          "19-docker" = {
            matchConfig.Name = "veth*";
            linkConfig = {
              Unmanaged = true;
            };
          };
        };

        networking.hostName = lib.mkForce name;
      };

      specialArgs = {
        inherit inputs cala-m-os initialInstallMode;
      };
    })
    vms;
in {
  imports = [inputs.microvm.nixosModules.host] ++ host_files;

  systemd.network.networks."${cala-m-os.networking.network-name}-noip" = {
    matchConfig.Name = "vm-*";

    linkConfig = {
      Unmanaged = true;
      RequiredForOnline = false;
    };

    networkConfig = {
      DHCP = false;
      LinkLocalAddressing = false;
    };

    address = [];
  };

  microvm.vms = vm_configs;
}
