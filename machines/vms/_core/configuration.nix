{
  cores,
  memory,
}: {
  lib,
  inputs,
  ...
}: {
  imports = [inputs.microvm.nixosModules.microvm];

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
  };
}
