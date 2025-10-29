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
  users.users."${cala-m-os.globals.defaultUser}".extraGroups = ["docker"];

  # Arion configuration
  virtualisation.arion = {
    backend = "docker";
    projects.lancache = {
      serviceName = "lancache";
      settings = {
        imports = [(import ./lancache/arion-compose.nix {inherit cala-m-os;})];
      };
    };
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/mnt/cache" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.media.lancache}";
    fsType = "nfs";
  };

  services.resolved.enable = false;

  systemd.network.networks."19-docker" = {
    matchConfig.Name = "veth*";
    linkConfig = {
      Unmanaged = true;
    };
  };
}
