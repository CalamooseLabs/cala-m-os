# Hetzner Cloud CAX (Ampere Altra, aarch64) hardware profile.
#
# The stage-1 module set published for CAX VMs (NixOS wiki); qemu-guest.nix,
# imported by configuration.nix, adds the rest of the virtio drivers. Safe to
# regenerate on the real box (nixos-anywhere --generate-hardware-config
# nixos-generate-config <this file>), but keep the hostPlatform line: it is what
# makes this machine aarch64 (mkSystem's `system` argument is only the fallback
# for machines that don't set one).
{lib, ...}: {
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "usbhid"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
