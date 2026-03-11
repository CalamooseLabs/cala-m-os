###################################
#                                 #
#          Simple Setup           #
#                                 #
###################################
{pkgs, ...}: let
  hostname = baseNameOf (toString ./.);
  users = ["basic"];

  machine_type = "Workstation";
  machine_uuid = "FW13-11XXP";
in {
  imports = [
    # Hardware Config

    # Common Core Config
    (import ../_core/configuration.nix {
      users_list = users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  # Enable CUPS to print documents.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };

  # Audio Control
  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Mount usb drives
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  networking.hostName = hostname;
}
