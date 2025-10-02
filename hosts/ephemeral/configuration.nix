##################################
#                                #
#      Ephemeral Lab Machine     #
#                                #
##################################
{
  inputs,
  lib,
  initialInstallMode,
  ...
}: let
  import_users = ["void"];

  machine_type = "Workstation";
  machine_uuid = "A520M-ITX";
in {
  imports =
    [
      inputs.impermanence.nixosModules.impermanence

      # Common Core Config
      (import ../_core/default.nix {
        users_list = import_users;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ]
    ++ lib.optional (!initialInstallMode) ./vms.nix;

  networking.hostName = "ephemeral";

  environment.persistence."/persistent" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/log"
      "/etc/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/nixos"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
