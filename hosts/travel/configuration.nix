##################################
#                                #
#   Torrent Management Server    #
#                                #
##################################
{lib, ...}: let
  import_users = ["voider"];

  machine_type = "VM";
  machine_uuid = "Small";
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

  # X Server is required
  services.xserver.enable = true;

  # Display Manager & Desktop
  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;
  # services.gnome.core-apps.enable = false;
  # services.gnome.core-developer-tools.enable = false;
  # services.gnome.games.enable = false;

  # Audio (PipeWire will handle the GPU's audio output)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # services.greetd.enable = lib.mkForce false;
}
