##################################
#                                #
#   Framework 12th Gen. Laptop   #
#                                #
##################################

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];

  # Use the systemd-boot EFI boot loader.
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

  networking = {
    hostName = "calamooselabs";
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/Chicago";


  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Framework BIOS updates
  services.fwupd.enable = true;

  # Mount usb drives
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ccalamos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [
    ];
  };

  security.sudo.extraRules = [{
    users = [ "ccalamos" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git # Git version control
    neovim # Neovim editor
    lf # CLI file explorer
    acpi # Battery indicator cli
    rofi-wayland # App Launcher
    zed-editor # Code Editor
    vivaldi # Browser
    proton-pass # Password Manager
    btop # System Monitor
    zathura # PDF Viewer
    qutebrowser # VIM-like Browser
    lazygit # Git cli manager
    bat # Better cat
    waybar # Topbar
    plex-desktop # Plex
    pavucontrol # Volume Mixer
    playerctl # Media Controls
    brightnessctl # Brightness control
    gnupg # GPG
    pinentry # GPG required
    imagemagick # Image manipulation
  ] ++ ([
    # From Flake
    inputs.ghostty.packages."${pkgs.system}".default # Terminal
  ]);

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry;
  };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  };

  programs.hyprlock = {
    enable = true;
    package = inputs.hyprlock.packages."${pkgs.system}".default;
  };

  security = {
    polkit.enable = true;
    pam.services.hyprlock = {};
  };


  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  fileSystems."/mnt/backups" = {
    device = "nas.calamos.family:/mnt/Media Library/Backups";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
    ];
  };

  system.stateVersion = "24.11"; # Did you read the comment?
}
