##################################
#                                #
#      Ephemeral Lab Machine     #
#                                #
##################################
{inputs, ...}: let
  import_users = ["void"];

  machine_type = "Workstation";
  machine_uuid = "ZIMA";
in {
  imports = [
    inputs.preservation.nixosModules.default

    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
    })
  ];

  networking.hostName = "ephemeral";

  preservation = {
    enable = true;

    preserveAt."/persistent" = {
      directories = [
        "/etc/nixos"
        "/var/lib/bluetooth"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
      ];

      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
      ];
    };
  };
}
