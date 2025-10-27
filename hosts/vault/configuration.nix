##################################
#                                #
#       Lan Cache Server        #
#                                #
##################################
{inputs, ...}: let
  import_users = ["server"];

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

    inputs.arion.nixosModules.arion
  ];

  networking.hostName = "vault";

  # Enable Docker for Arion
  virtualisation.docker.enable = true;

  # Arion configuration
  virtualisation.arion = {
    backend = "docker";
    projects.lancache = {
      serviceName = "lancache";
      settings = {
        imports = [./lancache/arion-compose.nix];
      };
    };
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/mnt/cache/lancache" = {
    device = "nas.calamos.family:/mnt/Media Library/Cache";
    fsType = "nfs";
  };
}
