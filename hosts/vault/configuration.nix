##################################
#                                #
#       Lan Cache Server        #
#                                #
##################################
{
  inputs,
  pkgs,
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

    inputs.lancache-nix.nixosModules.default
  ];

  networking.hostName = "vault";

  boot.supportedFilesystems = ["nfs"];

  # Enable nginx with slice module (required)
  services.nginx.package = pkgs.nginxMainline.override {withSlice = true;};

  services.lancache = {
    enable = true;
    cacheLocation = "/mnt/cache/lancache";
    logPrefix = "/var/log/nginx/lancache";
    listenAddress = "10.10.10.33";

    # Optional configurations
    upstreamDns = ["1.1.1.1" "1.0.0.1"];
    cacheDiskSize = "1000g";
    cacheIndexSize = "500m";
    cacheMaxAge = "3560d";
    minFreeDisk = "10g";
    sliceSize = "1m";
    logFormat = "cachelog";
    workerProcesses = "auto";
  };

  fileSystems."/mnt/cache/lancache" = {
    device = "nas.calamos.family:/mnt/Media Library/Cache";
    fsType = "nfs";
  };
}
