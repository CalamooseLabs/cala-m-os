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

  # DO NOT enable microvm.graphics - that's for virtual GPU only!
  # microvm.graphics.enable = false;  # Not needed, false by default

  # X Server is required
  services.xserver.enable = true;
  services.xserver.videoDrivers = ["nvidia"];

  # Display Manager & Desktop
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;

  # Audio (PipeWire will handle the GPU's audio output)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Graphics support
  hardware.graphics.enable = true;

  # NVIDIA driver configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = true; # Use proprietary driver for RTX 5090
    nvidiaSettings = true;
  };

  # Ensure shell is available (GDM requirement)
  programs.bash.enable = true;

  boot.plymouth.enable = lib.mkForce true;
}
