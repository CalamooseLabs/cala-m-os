##################################
#                                #
#   Torrent Management Server    #
#                                #
##################################
{...}: let
  import_users = ["voider"];

  machine_type = "VM";
  machine_uuid = "Medium";
in {
  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "testhtpc";

  # Mount usb drives
  # services.devmon.enable = true;
  # services.gvfs.enable = true;
  # services.udisks2.enable = true;

  # # Audio Control
  # services.pulseaudio.enable = false;

  # security.rtkit.enable = true;

  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   wireplumber.enable = true;
  # };

  hardware.graphics.enable = true;
}
