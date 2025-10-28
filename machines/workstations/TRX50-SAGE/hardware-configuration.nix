{
  config,
  lib,
  modulesPath,
  cala-m-os,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" "raid0"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd" "dm-raid" "raid0"];
  boot.extraModulePackages = [];
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR <mailto:${cala-m-os.globals.defaultEmail}>
    '';
  };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
