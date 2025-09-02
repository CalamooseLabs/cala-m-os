##################################
#                                #
#        Home Theater PC         #
#                                #
##################################
{...}: let
  import_users = [
    # Default User
    "gamer"

    # Other Users
  ];

  machine_type = "Workstation";
  machine_uuid = "AMD-X86_64";
in {
  imports = [
    # Common Core Config
    (import ../_core/configuration.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "htpc";

  services.openssh = {
    enable = true;
  };

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
