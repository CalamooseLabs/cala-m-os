##################################
#                                #
#     Framework 16 AMD Laptop    #
#                                #
##################################
{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix
    inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
  ];

  # Power saver for laptops
  networking.networkmanager.wifi.powersave = true;

  # Framework BIOS updates
  services.fwupd = {
    enable = true;
    extraRemotes = ["lvfs-testing"];
    uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Thunderbolt
  # Enable systemd in initrd
  boot.initrd.systemd.enable = true;

  # Include bolt in initrd
  boot.initrd.services.udev.packages = [pkgs.bolt];
  boot.initrd.systemd.packages = [pkgs.bolt];

  # Alternative: Manual udev rule for authorization
  boot.initrd.services.udev.rules = ''
    ACTION=="add|change", SUBSYSTEM=="thunderbolt", \
    ATTR{unique_id}=="<YOUR_DEVICE_UNIQUE_ID>", \
    ATTR{authorized}="1"
  '';

  services.hardware.bolt.enable = true;

  hardware.nvidia.prime = {
    amdgpuBusId = "PCI:195:0:0";
    nvidiaBusId = "PCI:194:0:0";
  };

  # Prevent backpack wake ups
  services.udev.extraRules = lib.mkAfter ''
    SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0012", ATTR{power/wakeup}="disabled", ATTR{driver/1-1.1.1.4/power/wakeup}="disabled"
    SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0014", ATTR{power/wakeup}="disabled", ATTR{driver/1-1.1.1.4/power/wakeup}="disabled"
  '';

  boot.kernelParams = ["amdgpu.abmlevel=0"];

  services.pipewire.wireplumber.extraConfig.no-ucm = {
    "monitor.alsa.properties" = {
      "alsa.use-ucm" = false;
    };
  };

  hardware.enableAllFirmware = true;

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
