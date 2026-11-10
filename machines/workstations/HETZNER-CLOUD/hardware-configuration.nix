# Hetzner Cloud (AMD) hardware profile.
#
# PLACEHOLDER / safe superset — REGENERATE on the real box, then commit it.
# nixos-anywhere does that as part of a first install, through
#     --generate-hardware-config nixos-generate-config \
#       ./machines/workstations/HETZNER-CLOUD/hardware-configuration.nix
# Use the FULL command in hosts/tci-cloud/configuration.nix (header, first
# install, step 3), not a bare one: it also runs under sudo (only root's nix
# can fetch the private flake input) and seeds the Proton Pass PAT with
# --extra-files, without which the install fails at activation. The
# bootloader (systemd-boot, UEFI) comes from hosts/_core; this file carries
# the hardware scan and nixpkgs.hostPlatform (keep that line when
# regenerating).
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # virtio disk/NIC + stage-1 essentials for a QEMU/KVM Cloud VM. A safe superset;
  # the generated file is authoritative for the exact controller set.
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

  # AMD Ryzen microcode (redistributable firmware; _core/non-vm enables unfree).
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
