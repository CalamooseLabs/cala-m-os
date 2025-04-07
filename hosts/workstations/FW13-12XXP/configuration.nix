##################################
#                                #
#   Framework 12th Gen. Laptop   #
#                                #
##################################
{inputs, ...}: let
  import_users = [
    # Default User
    "ccalamos"

    # Other Users
    "hub"
    "developer"
  ];
in {
  imports = [
    # Hardware Config
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel

    # SOPS for secret management
    inputs.sops-nix.nixosModules.sops
    # inputs.agenix.nixosModules.default

    # Common Core Config
    (import ../_core/configuration.nix {users_list = import_users;})
  ];

  networking = {
    hostName = "calamooselabs";

    # Power saver for laptops
    networkmanager.wifi.powersave = true;
  };

  # Framework BIOS updates
  services.fwupd = {
    enable = true;
    extraRemotes = ["lvfs-testing"];
    uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;
  };

  # Mount usb drives
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # SOPS
  sops = {
    defaultSopsFormat = "json";
    age.keyFile = "/etc/sops/key.txt";
  };
}
