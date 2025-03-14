{users_list, ...}: {lib, ...}: let
  usersPath = ../../../users;

  getUsers = name: import "${toString (usersPath + "/${name}/default.nix")}";

  user_imports = map getUsers users_list;
in {
  imports = [./home.nix] ++ user_imports;

  # Boot loader
  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    plymouth = {
      enable = true;
    };

    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    tmp.useTmpfs = true;

    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  # Remove manuals, as we google everything anyways
  documentation.enable = false;

  # Enable Network Manager
  networking.networkmanager.enable = true;

  # Set Chicago timezone
  time.timeZone = "America/Chicago";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Audio Control
  services.pulseaudio.enable = false; # Use Pipewire, the modern sound subsystem

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Allow unfree
  nixpkgs.config.allowUnfree = true;

  # Login Service
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = lib.mkForce "${lib.elemAt users_list 0}";
      };
    };
  };

  # Garbage Collection & Flakes
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };

    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
  };

  # Original State Version
  system.stateVersion = "24.11"; # Do not change
}
