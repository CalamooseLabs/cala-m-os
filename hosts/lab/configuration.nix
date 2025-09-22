##################################
#                                #
#           Lab Server           #
#                                #
#     Used for the Following:    #
#     - HTPC                     #
#     - Plex Server              #
#     - Studio Stream            #
#     - Torrent Manager          #
#                                #
##################################
{
  lib,
  initialInstallMode,
  ...
}: let
  users = ["server"];

  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";

  vms = {
    "media" = {
      devices = ["arc-a310"];
      storage = 100; # GBs
      macID = "01";
    };
  };

  bridgeInterface = "eno2";
in {
  imports =
    if !initialInstallMode
    then [
      (import ../../services/vm-manager/default.nix {
        device_path = ./devices;
        vms = vms;
        networkInterface = bridgeInterface;
      })
      (import ../_core/default.nix {
        users_list = users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ]
    else [
      (import ../_core/default.nix {
        users_list = users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ];

  networking.hostName = "lab";
}
