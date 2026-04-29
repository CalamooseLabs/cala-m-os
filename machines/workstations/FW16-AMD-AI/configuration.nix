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

  systemd.services.inhibit-sleep-after-resume = {
    description = "Temporary sleep inhibitor after resume (workaround for double-suspend)";
    wantedBy = ["post-resume.target"];
    after = ["post-resume.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.systemd}/bin/systemd-inhibit \
        --mode=block \
        --what=sleep:idle \
        --why="Workaround: avoid immediate second suspend after resume" \
        ${pkgs.coreutils}/bin/sleep 60
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
