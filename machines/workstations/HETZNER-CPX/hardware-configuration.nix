# Hetzner Cloud CPX (AMD EPYC, x86_64) hardware profile.
#
# A safe superset of the virtio stage-1 modules for a QEMU/KVM Cloud VM;
# qemu-guest.nix, imported by configuration.nix, adds the rest. Safe to
# regenerate on the real box (nixos-anywhere --generate-hardware-config
# nixos-generate-config <this file>), but keep the hostPlatform line.
{
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_net"
    "sr_mod"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  # No linux-firmware or microcode: virtio devices need no blobs, microcode is
  # the hypervisor's job, and the 20 GB disk has no room to spare.

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
