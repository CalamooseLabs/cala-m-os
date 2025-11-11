##################################
#                                #
#        Lan Station VMs         #
#                                #
##################################
{lib, ...}: let
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

    # kernelParams = [
    #   "nokaslr"
    #   "amdgpu.dc=0" # Disable Display Core to prevent crash
    #   "amdgpu.modeset=1" # Force kernel modesetting
    # ];

    # Use VM's own store disk as base
    storeOnDisk = true;

    # Enable writable overlay for building
    writableStoreOverlay = "/nix/.rw-store";
  };

  # services.resolved = {
  #   enable = true;
  # };
}
