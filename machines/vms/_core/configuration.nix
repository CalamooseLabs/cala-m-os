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
    hypervisor = lib.mkDefault "qemu";
    graphics.enable = lib.mkDefault false;

    writableStoreOverlay = lib.mkDefault "/nix/.rw-store";

    # Share memory for better performance
    # shares = [
    # ];
  };

  networking = {
    useDHCP = false;
  };
}
