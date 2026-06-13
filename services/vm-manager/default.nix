{
  config,
  lib,
  inputs,
  initialInstallMode,
  cala-m-os,
  ...
}: let
  cfg = config.services.cala-vm-manager;

  getDeviceFiles = device: filename: import (cfg.devicePath + "/${device}/${filename}");

  vmModule = lib.types.submodule {
    options = {
      storage = lib.mkOption {
        type = lib.types.ints.positive;
        description = "Root volume size in GB.";
      };

      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Device names (under devicePath) to pass through to this guest.";
      };

      shares = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [];
        description = "Extra microvm.shares entries for this guest.";
      };

      autostart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the guest starts automatically with the host.";
      };

      shareStore = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Share the host /nix/store with the guest (read-only).";
      };

      storeOnDisk = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Give the guest a writable on-disk nix store volume.";
      };

      hostOverride = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Host config to build this guest from, when it differs from the VM's attribute name.";
      };

      ipOverride = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Static IP to assign, overriding any lookup in settings.nix.";
      };

      gatewayOverride = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Gateway to use, overriding the default from settings.nix.";
      };

      dns = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "DNS servers for the guest; defaults to the gateway when null.";
      };

      mac = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Explicit MAC address; derived from the IP or name when null.";
      };
    };
  };

  vm_configs =
    builtins.mapAttrs (name: vm: let
      staticIp =
        if vm.ipOverride != null
        then vm.ipOverride
        else (cala-m-os.ip.${name} or null);
      hasStaticIp = staticIp != null;
      gateway =
        if vm.gatewayOverride != null
        then vm.gatewayOverride
        else cala-m-os.ip.gateway;
      h = builtins.hashString "sha256" name;
      mac =
        if vm.mac != null
        then vm.mac
        else if hasStaticIp
        then "02:00:00:00:00:${lib.last (lib.splitString "." staticIp)}"
        else "02:${builtins.substring 0 2 h}:${builtins.substring 2 2 h}:${builtins.substring 4 2 h}:${builtins.substring 6 2 h}:${builtins.substring 8 2 h}";
    in {
      autostart = vm.autostart;
      config = {
        imports =
          [
            ../../hosts/${
              if vm.hostOverride != null
              then vm.hostOverride
              else name
            }/configuration.nix
          ]
          ++ (map (device: getDeviceFiles device "guest.nix") vm.devices);

        microvm = {
          interfaces = [
            {
              type = "macvtap";
              id = "vm-${name}";
              inherit mac;
              macvtap = {
                mode = "bridge";
                link = cfg.networkInterface;
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
            ++ lib.optionals vm.storeOnDisk [
              {
                image = "nix-store-${name}.img";
                mountPoint = "/nix/.rw-store";
                size = 51200; # 50GB
                autoCreate = true;
                fsType = "ext4";
              }
            ];

          shares =
            lib.optionals config.calamoose.enableSecrets [
              {
                proto = "virtiofs";
                tag = "agenix";
                source = "/run/agenix";
                mountPoint = "/run/hostsecrets";
              }
            ]
            ++ vm.shares
            ++ lib.optionals vm.shareStore [
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
          "${cala-m-os.networking.network-name}" =
            if hasStaticIp
            then {
              matchConfig.MACAddress = mac;
              address = ["${staticIp}/${cala-m-os.networking.prefixLength}"];
              routes = [
                {
                  Destination = "0.0.0.0/0";
                  Gateway = gateway;
                  GatewayOnLink = true;
                }
              ];
              networkConfig.DNS =
                if vm.dns != null
                then vm.dns
                else ["${gateway}"];
            }
            else {
              matchConfig.MACAddress = mac;
              networkConfig.DHCP = "yes";
            };

          "19-docker" = {
            matchConfig.Name = "veth*";
            linkConfig.Unmanaged = true;
          };
        };

        networking.hostName = lib.mkForce name;
      };

      specialArgs = {
        inherit inputs cala-m-os initialInstallMode;
      };
    })
    cfg.vms;
in {
  imports = [inputs.microvm.nixosModules.host];

  options.services.cala-vm-manager = {
    enable = lib.mkEnableOption "MicroVM host management for Cala-M-OS guests";

    devicePath = lib.mkOption {
      type = lib.types.path;
      description = "Directory holding per-device host.nix/guest.nix passthrough modules.";
    };

    networkInterface = lib.mkOption {
      type = lib.types.str;
      example = "eno2";
      description = "Host interface the guests' macvtap bridges attach to.";
    };

    vms = lib.mkOption {
      type = lib.types.attrsOf vmModule;
      default = {};
      description = "MicroVM guests to define on this host, keyed by name.";
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}
