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

    # Modules
    ../../modules/nvidia-gpu/configuration.nix
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

  # Nvidia 5070
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
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

  services.logind.settings.Login.HandleLidSwitch = "ignore";

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
