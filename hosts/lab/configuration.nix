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
{...}: let
  users = ["server"];

  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";

  vms = {
    "media" = {
      devices = ["arc-a310" "jetkvm-usb"];
      storage = 100; # GBs
      mac = "02:00:00:00:00:01";
    };
  };
in {
  imports = [
    # Import VMs
    (import ./vm-manager.nix vms)

    # Common Core Config
    (import ../_core/configuration.nix {
      users_list = users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "lab";
}
