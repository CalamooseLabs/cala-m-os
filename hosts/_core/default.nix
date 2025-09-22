{
  users_list,
  machine_type,
  machine_uuid,
  ...
}: {...}: let
  initialInstallMode = builtins.getEnv "INITIAL_INSTALL_MODE" == "1";
in {
  imports =
    if initialInstallMode
    then [
      (import ../../iso/minimal-config/configuration.nix {
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ]
    else [
      (import ./configuration.nix {
        users_list = users_list;
        machine_type = machine_type;
        machine_uuid = machine_uuid;
      })
    ];
}
