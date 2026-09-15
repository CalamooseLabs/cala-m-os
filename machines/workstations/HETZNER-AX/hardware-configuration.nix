# Bare-metal AMD (Hetzner AX-series) hardware profile.
#
# PLACEHOLDER / safe superset — REGENERATE on the real box, then commit it:
#   nix run github:nix-community/nixos-anywhere -- \
#     --flake .#tci-public \
#     --generate-hardware-config nixos-generate-config \
#       ./machines/workstations/HETZNER-AX/hardware-configuration.nix \
#     --target-host root@<SERVER_IP>
# (boot the box into the Hetzner Rescue System first, SSH key loaded). The
# bootloader (systemd-boot, UEFI) and hostPlatform come from hosts/_core; this
# file carries only the hardware scan.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # Disks + IPMI/USB console + stage-1 essentials. A safe superset for AX boxes;
  # the generated file is authoritative for the exact controller set.
  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "usbhid"
    "usb_storage"
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
