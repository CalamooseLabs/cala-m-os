##################################
#                                #
#        Lan Station VMs         #
#                                #
##################################
{
  lib,
  pkgs,
  ...
}: let
  import_users = ["gamer-vm"];

  machine_type = "VM";
  machine_uuid = "Large";
in {
  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  # Audio Control
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  microvm = {
    optimize.enable = false;
    balloon = lib.mkForce false;

    # Use VM's own store disk as base
    storeOnDisk = true;

    # Enable writable overlay for building
    writableStoreOverlay = "/nix/.rw-store";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };
  # services.resolved = {
  #   enable = true;
  # };
}
