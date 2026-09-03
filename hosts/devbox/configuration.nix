##################################
#                                #
#        Main Daily Laptop       #
#                                #
##################################
{
  inputs,
  lib,
  pkgs,
  initialInstallMode,
  ...
}: let
  import_users = [
    "debugger"
  ];

  machine_type = "Workstation";
  machine_uuid = "FW16-AMD-AI";
in {
  calamoose.version = "2.1.0";

  imports =
    [
      # Common Core Config
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
        extra_user_modules = {};
      })
    ]
    # bookkeeper (books) + its PRIVATE flake input need a GitHub PAT to fetch, and
    # neither belongs in the minimal installer pass (no token, no secrets facade there).
    ++ lib.optional (!initialInstallMode) {
      imports = [
        inputs.bookkeeper.nixosModules.default
        ../../modules/nix-github-token/configuration.nix
      ];

      services.calamoose-books.enable = true;

      # devbox uses agenix (its default backend). The token is an .age encrypted to the
      # Yubikeys (modules/nix-github-token/secrets/secrets.nix). Create it once with:
      #   cd modules/nix-github-token/secrets && agenix -e nix-github-token.age
      #   # plaintext: access-tokens = github.com=github_pat_…
      programs.nix-github-token = {
        enable = true;
        agenixFile = ../../modules/nix-github-token/secrets/nix-github-token.age;
      };
    };

  networking.hostName = "devbox";

  # Drifting (animated) lockscreen background on the laptop.
  cala.lockscreen.background = "static";

  # Waybar button that swaps the desktop wallpaper to the brand art at runtime,
  # so a personal photo background never lands on a stream. Click to hide/reveal.
  cala.waybar.streamPrivacy.enable = true;

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
