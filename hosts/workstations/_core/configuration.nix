{ users_list, ... }: { inputs, pkgs, ... }:
let
  usersPath = ../../../users;

  getUsers = name: import "${toString (usersPath + "/${name}/default.nix")}";

  user_imports = map getUsers users_list;
in
{
  imports = [ ./home.nix ] ++ user_imports;

  # Boot loader
  boot = {
    loader = {
      timeout = 0;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    plymouth = {
      enable = true;
      logo = ../../../assets/logo-100x100.png;
      theme = "breeze";
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

    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  # Remove manuals, as we google everything anyways
  documentation.enable = false;

  # Enable Network Manager
  networking.networkmanager.enable = true;

  # Set Chicago timezone
  time.timeZone = "America/Chicago";

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # Enable hyprland
  # programs.hyprland = {
  #   enable = true;
  #   package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  #   portalPackage = inputs.hyprland.packages."${pkgs.system}".xdg-desktop-portal-hyprland;
  # };

  # Original State Version
  system.stateVersion = "24.11"; # Do not change
}
