##################################
#                                #
#        Main Daily Laptop       #
#                                #
##################################
{
  lib,
  pkgs,
  ...
}: let
  import_users = [
    "debugger"
  ];

  machine_type = "Workstation";
  machine_uuid = "FW16-AMD-AI";
in {
  calamoose.version = "2.1.0";

  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

  networking.hostName = "devbox";

  # Drifting (animated) lockscreen background on the laptop.
  cala.lockscreen.background = "static";

  # Enable CUPS to print documents.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      canon-cups-ufr2
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

  # Devbox can have manual
  documentation.enable = lib.mkForce true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # The MSI MPG 322URX QD-OLED exposes a tiny built-in USB mass-storage gadget
  # ("Optix Driver" — /dev/sda, a 22K vfat volume, vendor 1462) meant to
  # auto-install its Windows software. It's harmless on Linux but shows up as an
  # always-present removable drive; tell udisks to ignore it so it stops
  # appearing in the file manager / desktop.
  services.udev.extraRules = ''
    SUBSYSTEM=="block", ENV{ID_VENDOR_ID}=="1462", ENV{ID_MODEL}=="Optix_Driver", ENV{UDISKS_IGNORE}="1"
  '';
}
