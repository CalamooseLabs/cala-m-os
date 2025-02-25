##################################
#                                #
#   Framework 12th Gen. Laptop   #
#                                #
##################################

{ pkgs, inputs, ... }:

let
  import_users = [
    "ccalamos"
  ];

  usersPath = ../../../users;

  getUsers = name: import "${toString (usersPath + "/${name}/default.nix")}";

  userList = map getUsers import_users;
in
{
  imports =
    [
      # Hardware Config
      ./hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.framework-12th-gen-intel

      # Common Core Config
      ../_core/configuration.nix
    ] ++ userList;

  networking = {
    hostName = "calamooselabs";
  };

  # Framework BIOS updates
  services.fwupd.enable = true;

  # Mount usb drives
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    # git # Git version control
    # neovim # Neovim editor
    # lf # CLI file explorer
    acpi # Battery indicator cli
    # rofi-wayland # App Launcher
    # zed-editor # Code Editor
    # vivaldi # Browser
    proton-pass # Password Manager
    # btop # System Monitor
    # zathura # PDF Viewer
    qutebrowser # VIM-like Browser
    # lazygit # Git cli manager
    # bat # Better cat
    # waybar # Topbar
    plex-desktop # Plex
    pavucontrol # Volume Mixer
    playerctl # Media Controls
    brightnessctl # Brightness control
    # gnupg # GPG
    # pinentry # GPG required
    imagemagick # Image manipulation
    # direnv # Automatic devenv setup
  ];
    # ] ++ ([
    # From Flake
    # inputs.ghostty.packages."${pkgs.system}".default # Terminal
  # ]);

  # Plex needs this to login/click on links.
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  #   xdgOpenUsePortal = true;
  # };

  # programs.gnupg.agent = {
  #   enable = true;
  #   pinentryPackage = pkgs.pinentry;
  # };

   # programs.hyprland = {
   #   enable = true;
   #   package = inputs.hyprland.packages."${pkgs.system}".hyprland;
   #   portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
   # };

  # programs.hyprlock = {
  #   enable = true;
  #   package = inputs.hyprlock.packages."${pkgs.system}".default;
  # };

  # security = {
  #   polkit.enable = true;
  #   pam.services.hyprlock = {};
  # };

  fileSystems."/mnt/backups" = {
    device = "nas.calamos.family:/mnt/Media Library/Backups";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
    ];
  };
}
