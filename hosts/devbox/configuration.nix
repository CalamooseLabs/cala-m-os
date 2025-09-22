##################################
#                                #
#        Main Daily Laptop       #
#                                #
##################################
{
  lib,
  pkgs,
  config,
  ...
}: let
  import_users = [
    # Default User
    "debugger"

    # Other Users
  ];

  machine_type = "Workstation";
  machine_uuid = "FW13-12XXP";

  caddyConfig = {
    "localhost:32400" = {
      tokenPath = config.age.secrets.plex-cloudflare-token.path;
      aliases = ["plex.yourdomain.com"];
    };
  };
in {
  imports = [
    ./secrets

    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })

    # Caddy SSL
    (import ../../services/caddy/default.nix {
      caddyConfig = caddyConfig;
    })
  ];

  networking.hostName = "devbox";

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

  # Devbox can have manual
  documentation.enable = lib.mkForce true;
}
