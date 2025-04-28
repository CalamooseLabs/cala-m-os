##################################
#                                #
#        Main Daily Laptop       #
#                                #
##################################
{...}: let
  import_users = [
    # Default User
    "debugger"

    # Other Users
  ];

  machine_type = "Workstation";
  machine_uuid = "FW13-12XXP";
in {
  imports = [
    # Common Core Config
    (import ../_core/configuration.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
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
