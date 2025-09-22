{
  users_list,
  machine_type,
  machine_uuid,
  ...
}: {initialInstallMode, ...}: {
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
