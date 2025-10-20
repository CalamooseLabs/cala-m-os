##################################
#                                #
#   Torrent Management Server    #
#                                #
##################################
{...}: let
  import_users = ["mixer"];

  machine_type = "VM";
  machine_uuid = "Small";
in {
  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "studio";

  # Audio (PipeWire will handle the GPU's audio output)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  microvm.hypervisor = "cloud-hypervisor";
}
