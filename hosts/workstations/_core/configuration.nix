{ ... }:

{
  # import = [
  #   # Home Manager
  #   inputs.home-manager.nixosModules.default

  #   # Theme
  #   # inputs.catppuccin.nixosModules.catppuccin
  # ];

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

  # Add Home Manager
  # home-manager = {
  # };

  # Original State Version
  system.stateVersion = "24.11"; # Do not change
}
