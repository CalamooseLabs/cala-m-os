{
  cores,
  memory,
}: {
  lib,
  inputs,
  config,
  ...
}: {
  imports = [inputs.microvm.nixosModules.microvm];

  microvm = {
    # VM resources
    vcpu = cores;
    mem = 1024 * memory;
    balloon = lib.mkDefault true;

    # Hypervisor settings
    hypervisor = lib.mkDefault "qemu";
    graphics.enable = lib.mkDefault false;

    writableStoreOverlay = lib.mkDefault "/nix/.rw-store";

    # Share memory for better performance
    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];

    volumes = [
      {
        image = "nix-store-overlay.img";
        mountPoint = config.microvm.writableStoreOverlay;
        size = 2048; # Size in MB
      }
    ];
  };

  networking = {
    useDHCP = false;
  };
}
