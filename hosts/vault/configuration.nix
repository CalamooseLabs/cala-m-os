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

    inputs.lancache.nixosModules.dns
    inputs.lancache.nixosModules.cache
  ];

  networking.hostName = "vault";

  services.plex = {
    enable = true;
    openFirewall = true;
  };

  boot.supportedFilesystems = ["nfs"];

  services.lancache = {
    dns = {
      enable = true;
      forwarders = ["1.1.1.1" "8.8.8.8"];
      cacheIp = "10.10.10.15";
    };

    cache = {
      enable = true;
      resolvers = ["1.1.1.1" "8.8.8.8"];
    };
  };

  fileSystems."/data/cache/cache" = {
    device = "nas.calamos.family:/mnt/Media Library/Cache";
    fsType = "nfs";
  };
}
