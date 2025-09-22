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
{lib, ...}: let
  initialInstallMode = builtins.getEnv "INITIAL_INSTALL_MODE" == "1";

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
    [
      # Common Core Config
      (import ../_core/default.nix {
        users_list = users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ]
    ++ lib.optional (!initialInstallMode)
    (import ../../services/vm-manager/default.nix {
      device_path = ./devices;
      vms = vms;
      networkInterface = bridgeInterface;
    });

  networking.hostName = "lab";
}
