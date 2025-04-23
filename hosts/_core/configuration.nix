{users_list, ...}: {lib, ...}: let
  usersPath = ../../../users;

  getUsers = name: import "${toString (usersPath + "/${name}/default.nix")}";

  user_imports = map getUsers users_list;
in {
  imports =
    [./home.nix] ++ user_imports;

  # Boot loader
  boot = {
    loader = {
      timeout = lib.mkForce 0;
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

    # Trying to move this to disko
    tmp.useTmpfs = true;

    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  # Remove manuals, as we google everything anyways
  documentation.enable = false;

  # Enable Firewall
  networking.firewall.enable = true;

  # Enable Network Manager
  networking.networkmanager.enable = true;

  # Set Chicago timezone
  time.timeZone = "America/Chicago";

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
