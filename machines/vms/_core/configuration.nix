{
  cores,
  memory,
}: {
  lib,
  vmName,
  vmConfig,
  vmDeviceFiles,
  vmBridge,
  ...
}: {
  imports = vmDeviceFiles;

  microvm = {
    # VM resources
    vcpu = cores;
    mem = 1024 * memory;
    balloon = lib.mkDefault true;

    # Hypervisor settings
    hypervisor = "qemu";
    graphics.enable = false;

    # Share memory for better performance
    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];

    interfaces = [
      {
        type = "macvtap";
        id = "vm-${vmName}";
        mac = "02:00:00:00:00:${vmConfig.macID}";
        mode = "bridge";
        link = "${vmBridge}";
      }
      {
        type = "tap";
        id = "vm-${vmName}--to-host";
        mac = "02:00:00:00:01:${vmConfig.macID}";
      }
    ];

    volumes = [
      {
        image = "${vmName}-vm.img";
        mountPoint = "/";
        size = vmConfig.storage * 1024;
      }
    ];
  };

  networking = {
    useDHCP = false;
    interfaces."${vmBridge}".useDHCP = true;
  };
}
