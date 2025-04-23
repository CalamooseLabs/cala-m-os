##################################
#                                #
#        Main Daily Laptop       #
#                                #
##################################
{inputs, ...}: let
  import_users = [
    # Default User
    "hub"

    # Other Users
  ];
in {
  imports = [
    # Hardware Config
    inputs.disko.nixosModules.disko
    ../../machines/workstations/FW13-12XXP/configuration.nix

    # Common Core Config
    (import ../_core/configuration.nix {users_list = import_users;})
  ];

  networking.hostName = "devbox";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Mount usb drives
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Audio Control
  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
}
