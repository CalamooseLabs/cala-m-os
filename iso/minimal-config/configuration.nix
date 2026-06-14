{
  machine_type,
  machine_uuid,
  ...
}: {
  lib,
  pkgs,
  machineOverride ? "",
  ...
}: let
  machine = import ../../machines/resolve.nix {
    inherit machine_type machine_uuid machineOverride;
  };

  machine_hardware = import (machine.path + "/hardware-configuration.nix");
  machine_disko = import (machine.path + "/disko.nix");
in {
  imports = [
    ../../hosts/_core/options.nix
    machine_hardware
    "${fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
    machine_disko
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = lib.mkForce "nixos-temp";

  networking.networkmanager.enable = true;

  time.timeZone = "America/Denver";

  nix.settings.experimental-features = ["nix-command" "flakes"];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    disko
    git
  ];

  services.pcscd.enable = true;

  system.stateVersion = "25.11";
}
