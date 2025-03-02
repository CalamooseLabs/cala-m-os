##################################
#                                #
#   Framework 12th Gen. Laptop   #
#                                #
##################################

{ inputs, ... }:

let
  import_users = [
    # Default User
    "ccalamos"

    # Other Users
    "hub"
  ];
in
{
  imports =
    [
      # Hardware Config
      ./hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.framework-12th-gen-intel

      # Common Core Config
      (import ../_core/configuration.nix { users_list = import_users; })
    ];

  networking = {
    hostName = "calamooselabs";
  };

  # Framework BIOS updates
  services.fwupd.enable = true;

  # Mount usb drives
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
}
