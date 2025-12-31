##################################
#                                #
#     Framework 16 AMD Laptop    #
#                                #
##################################
{
  inputs,
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

  # Nvidia 5070
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = true;
      nvidiaSettings = true;
      prime = {
        offload.enable = true;
        amdgpuBusId = "PCI:195:0:0";
        nvidiaBusId = "PCI:194:0:0";
      };
    };
  };

  boot.kernelParams = ["nvidia-drm.modeset=1"];

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
