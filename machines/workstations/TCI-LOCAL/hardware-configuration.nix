# Local TCI-private box hardware profile.
#
# PLACEHOLDER / safe superset — REGENERATE on the real box and commit it:
#   nixos-generate-config --show-hardware-config \
#     > machines/workstations/TCI-LOCAL/hardware-configuration.nix
# The bootloader (systemd-boot, UEFI) + hostPlatform come from hosts/_core; this
# file carries only the hardware scan. Add "kvm-amd"/"kvm-intel" to
# boot.kernelModules only if this box will host VMs (a game server needs neither).
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  hardware.enableRedistributableFirmware = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
