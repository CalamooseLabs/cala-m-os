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
in {
  imports = [
    ./secrets
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
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

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
      hash = "sha256-j+xUy8OAjEo+bdMOkQ1kVqDnEkzKGTBIbMDVL7YDwDY=";
    };

    virtualHosts."plex-test.calamos.family".extraConfig = ''
      tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
      }

      respond "Hello, world!"
    '';

    globalConfig = ''
      acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
    '';
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [config.age.secrets.plex-cloudflare-token.path];
  # Devbox can have manual
  documentation.enable = lib.mkForce true;
}
