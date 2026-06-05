{
  users_list,
  machine_type,
  machine_uuid,
  extra_user_modules ? {},
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
        extra_user_modules = extra_user_modules;
      })
    ];
}
