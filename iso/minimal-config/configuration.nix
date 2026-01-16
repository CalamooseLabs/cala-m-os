{
  machine_type,
  machine_uuid,
  ...
}: {
  lib,
  pkgs,
  ...
}: let
  isVM = machine_type == "VM" || machine_type == "vm";
  machine_root =
    ../../machines
    + (
      if isVM
      then "/vms"
      else "/workstations"
    );
  machine_path = toString (machine_root + "/${machine_uuid}");

  machine_hardware = import (toString (machine_path + "/hardware-configuration.nix"));
  machine_disko = import (toString (machine_path + "/disko.nix"));
in {
  imports = [
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
