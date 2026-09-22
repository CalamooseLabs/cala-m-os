# Hetzner Cloud (AMD) hardware profile.
#
# PLACEHOLDER / safe superset — REGENERATE on the real box, then commit it:
#   nix run github:nix-community/nixos-anywhere -- \
#     --flake .#tci-cloud \
#     --generate-hardware-config nixos-generate-config \
#       ./machines/workstations/HETZNER-CLOUD/hardware-configuration.nix \
#     --target-host root@<SERVER_IP>
# (enable the Hetzner Rescue System on the instance first, SSH key loaded). The
# bootloader (systemd-boot, UEFI) and hostPlatform come from hosts/_core; this
# file carries only the hardware scan.
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
