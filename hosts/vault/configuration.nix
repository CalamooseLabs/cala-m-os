##################################
#                                #
#       Lan Cache Server        #
#                                #
##################################
{
  pkgs,
  cala-m-os,
  inputs,
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

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/mnt/cache/lancache" = {
    device = "nas.calamos.family:/mnt/Media Library/Cache";
    fsType = "nfs";
  };

  environment.systemPackages = [
    pkgs.arion

    pkgs.docker-client
  ];

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.dnsname.enable = true;

  users.extraUsers."${cala-m-os.globalDefaultUser}".extraGroups = ["podman"];

  virtualisation.arion = {
    backend = "podman-socket"; # or "docker"
    projects.example = {
      serviceName = "lancache"; # optional systemd service name, defaults to arion-example in this case
      settings = {
        # Specify you project here, or import it from a file.
        # NOTE: This does NOT use ./arion-pkgs.nix, but defaults to NixOS' pkgs.
        imports = [./lancache/arion-compose.nix];
      };
    };
  };
}
