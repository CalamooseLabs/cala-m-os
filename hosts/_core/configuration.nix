{
  users_list,
  machine_type,
  machine_uuid,
  ...
}: {
  inputs,
  lib,
  ...
}: let
  usersPath = ../../users;
  defaultUser = lib.elemAt users_list 0;

  isDefaultUser = name: name == defaultUser;
  getUsers = name:
    import (toString (usersPath + "/${name}/default.nix")) {
      inherit inputs lib;
      isDefaultUser = isDefaultUser name;
    };

  user_imports = map getUsers users_list;

  isVM = machine_type == "VM" || machine_type == "vm";
  machine_root =
    ../../machines
    + (
      if isVM
      then "/vms"
      else "/workstations"
    );
  machine_path = toString (machine_root + "/${machine_uuid}");

  machine_configuration = import (toString (machine_path + "/configuration.nix"));
in {
  imports =
    [
      inputs.disko.nixosModules.disko
      (import ./home.nix {
        machine_path = machine_path;
      })
      machine_configuration
    ]
    ++ user_imports;

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
        user = lib.mkForce "${defaultUser}";
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

  # Finer grain privileged process control
  security.polkit.enable = true;

  # Original State Version
  system.stateVersion = "24.11"; # Do not change
}
