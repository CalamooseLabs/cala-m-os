{
  config,
  lib,
  pkgs,
  inputs,
  initialInstallMode,
  cala-m-os,
  ...
}: let
  cfg = config.services.cala-vm-manager;

  # Host secrets shared into the guests (/run/hostsecrets). On the agenix
  # backend /run/agenix is a symlink that agenix repoints to a NEW
  # /run/agenix.d/<n> on every activation while deleting the old one — but a
  # guest's virtiofsd opened the old directory once at start, so after any host
  # rebuild the guests would see an empty share until restarted. Share a stable
  # directory instead, refreshed in place (same inode) after every decrypt:
  # by an activation snippet on rebuilds and by vm-hostsecrets-sync after the
  # post-boot agenix-rerun. The Proton backend writes a stable directory already.
  secretsBackend = config.calamoose._secretsBackend;
  useStableCopy = secretsBackend == "agenix" && config.age.secrets != {};
  hostSecretsDir = "/run/vm-hostsecrets";
  hostSecretsSource =
    if useStableCopy
    then hostSecretsDir
    else if secretsBackend == "proton-pass"
    then "/run/proton-secrets"
    else "/run/agenix";
  syncScript = pkgs.writeShellScript "vm-hostsecrets-sync" ''
    install -d -m 0751 ${hostSecretsDir}
    if [ -d /run/agenix/ ]; then
      ${pkgs.rsync}/bin/rsync -a --delete /run/agenix/ ${hostSecretsDir}/
    fi
  '';

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

      networkInterface = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Host interface this guest's macvtap bridge attaches to; falls back to services.cala-vm-manager.networkInterface when null.";
      };

      egressRateLimit = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "1500M";
        description = ''
          Cap this guest's egress (TX) with a Token Bucket Filter on its primary
          network. The value is the systemd-networkd `Rate=` in bits/s — "1500M"
          is 1.5 Gbit/s. Stops bulk writes (e.g. *arr imports copied to the NFS
          library) from saturating shared storage and starving other readers.
          Null disables shaping. Burst/latency are sized automatically.
        '';
      };
    };
  };

  vm_configs =
    builtins.mapAttrs (name: vm: let
      staticIp =
        if vm.ipOverride != null
        then vm.ipOverride
        else (cala-m-os.ip.lab.${name} or null);
      hasStaticIp = staticIp != null;
      gateway =
        if vm.gatewayOverride != null
        then vm.gatewayOverride
        else cala-m-os.ip.lab.gateway;
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
                link =
                  if vm.networkInterface != null
                  then vm.networkInterface
                  else cfg.networkInterface;
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
            lib.optionals config.calamoose._secretsEnabled [
              {
                proto = "virtiofs";
                tag = "agenix";
                # Backend-aware: share whichever runtime dir holds the decrypted
                # host secrets (see hostSecretsSource above). tag + mountPoint are
                # unchanged so guests keep using /run/hostsecrets/* regardless of
                # backend. Guests only ever read.
                source = hostSecretsSource;
                mountPoint = "/run/hostsecrets";
                readOnly = true;
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
            (
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
              }
            )
            // lib.optionalAttrs (vm.egressRateLimit != null) {
              # Shape transmit so a bulk NFS write burst can't saturate the link
              # (and the storage behind it). Burst ≈ rate/HZ headroom; the queue
              # is bounded by latency so backlog can't grow unbounded.
              tokenBucketFilterConfig = {
                Parent = "root";
                Rate = vm.egressRateLimit;
                BurstBytes = "2M";
                LatencySec = "50ms";
              };
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
        # Guests are always resolved as their declared machine_type ("VM"), so
        # there is no machine override. Supplying it here externally (rather than
        # letting it fall back to _module.args) is also load-bearing: _core's
        # configuration.nix consults machineOverride while computing `imports`,
        # which only terminates when the arg comes from specialArgs — otherwise
        # resolving it requires `config`, which requires `imports`: infinite
        # recursion. The top-level mkSystem passes it for the same reason.
        machineOverride = "";
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
    # On the agenix backend the host's secrets are only populated post-boot by
    # agenix-rerun (modules/agenix: stage-2 activation runs before pcscd exists,
    # so boot-time decryption always fails). The stable copy is refreshed right
    # after it, and every guest's virtiofsd (and thus the guest, which Requires
    # it) is ordered after that sync. Wants, not Requires: a guest that needs no
    # secrets (media) still boots if no YubiKey is present.
    systemd.services.vm-hostsecrets-sync = lib.mkIf useStableCopy {
      description = "Refresh the host-secrets directory shared into the MicroVM guests";
      wantedBy = ["multi-user.target"];
      wants = ["agenix-rerun.service"];
      after = ["agenix-rerun.service"];
      # `systemctl restart agenix-rerun` (the fix-up after a boot without the
      # YubiKey) re-runs this sync as well.
      partOf = ["agenix-rerun.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = syncScript;
      };
    };
    systemd.services."microvm-virtiofsd@" = lib.mkIf useStableCopy {
      after = ["vm-hostsecrets-sync.service"];
      wants = ["vm-hostsecrets-sync.service"];
    };
    # Rebuilds: re-sync right after agenix has written the new generation, so
    # running guests keep a valid, current view (same directory inode).
    system.activationScripts.vmHostSecretsSync = lib.mkIf useStableCopy {
      deps = ["agenix"];
      text = "${syncScript}";
    };

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
