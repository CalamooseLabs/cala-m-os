{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  # Deliberately lean: an internet-facing 1 GB box (cala-web) managed remotely
  # from devbox. Unlike `server`, there's no yubikey module: it brings the
  # yubioath-flutter GUI, which a headless box with a 20 GB disk doesn't need.
  # There's also no rebuild-config/restore-config, because deploys come from
  # devbox and the box has no /etc/nixos checkout.
  modules = [
    # Needed even with secrets off: modules/secrets (always imported by _core)
    # defines age.* under a false mkIf, and that still requires the options to
    # exist. Nothing is installed when the backend is "none".
    "agenix"
    "bash"
    "btop"
    "neovim"
    "nh"
    "openssh"
  ];
in {
  inherit modules;
  module = {cala-m-os, ...}: let
    username =
      if isDefaultUser
      then cala-m-os.globals.defaultUser
      else uuid;
  in {
    imports = [
      (import ../_core {
        username = username;
        import_modules = modules;
        uuid = uuid;
      })
    ];
  };
}
