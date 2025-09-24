##################################
#                                #
#        Home Theater PC         #
#                                #
##################################
{pkgs, ...}: let
  import_users = ["gamer"];

  machine_type = "VM";
  machine_uuid = "Large";
in {
  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "htpc";

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

  microvm.graphics.enable = true;
  microvm.hypervisor = "cloud-hypervisor";

  environment.sessionVariables = {
    WAYLAND_DISPLAY = "wayland-1";
    DISPLAY = ":0";
    QT_QPA_PLATFORM = "wayland"; # Qt Applications
    GDK_BACKEND = "wayland"; # GTK Applications
    XDG_SESSION_TYPE = "wayland"; # Electron Applications
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
  };

  systemd.user.services.wayland-proxy = {
    enable = true;
    description = "Wayland Proxy";
    serviceConfig = with pkgs; {
      # Environment = "WAYLAND_DISPLAY=wayland-1";
      ExecStart = "${wayland-proxy-virtwl}/bin/wayland-proxy-virtwl --virtio-gpu --x-display=0 --xwayland-binary=${xwayland}/bin/Xwayland";
      Restart = "on-failure";
      RestartSec = 5;
    };
    wantedBy = ["default.target"];
  };

  environment.systemPackages = with pkgs;
    [
      xdg-utils # Required
    ]
    ++ map (
      package:
        lib.attrByPath (lib.splitString "." package) (throw "Package ${package} not found in nixpkgs") pkgs
    ) (
      builtins.filter (
        package:
          package != ""
      ) (lib.splitString " " packages)
    );

  hardware.graphics.enable = true;
}
