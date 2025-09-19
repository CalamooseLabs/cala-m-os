{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
    ./disko.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-temp";

  networking.networkmanager.enable = true;

  time.timeZone = "America/Denver";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    disko
    git
  ];

  services.pcscd.enable = true;

  system.stateVersion = "25.11";
}
