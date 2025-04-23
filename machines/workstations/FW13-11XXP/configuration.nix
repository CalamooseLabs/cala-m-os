##################################
#                                #
#   Framework 11th Gen. Laptop   #
#                                #
##################################
{inputs, ...}: {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    ./disko.nix
    inputs.nixos-hardware.nixosModules.framework-11th-gen-intel
  ];

  networking = {
    # Power saver for laptops
    networkmanager.wifi.powersave = true;
  };

  # Framework BIOS updates
  services.fwupd = {
    enable = true;
    extraRemotes = ["lvfs-testing"];
    uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;
  };

  # Enable touchpad support
  services.libinput.enable = true;

  # Thunderbolt
  services.hardware.bolt.enable = true;

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
