##################################
#                                #
#       Lan Cache Server        #
#                                #
##################################
{
  inputs,
  cala-m-os,
  ...
}: let
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
  users.users."${cala-m-os.globalDefaultUser}".extraGroups = ["docker"];

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

  fileSystems."/mnt/cache" = {
    device = "nas.calamos.family:/mnt/Media Library/Cache";
    fsType = "nfs";
  };
}
