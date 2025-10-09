##################################
#                                #
#   Torrent Management Server    #
#                                #
##################################
{...}: let
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

  # Audio Control
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # services = {
  #   displayManager = {
  #     sddm.enable = true; # This is the key
  #     autoLogin = {
  #       enable = true;
  #       user = "hub";
  #     };
  #   };
  #   desktopManager.plasma6.enable = true;
  # };

  services.xserver.enable = true; # optional
  # services.displayManager.sddm.wayland.enable = true;

  # As of 25.11
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;

  hardware.graphics.enable = true;
}
