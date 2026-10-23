{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  # Deliberately lean: an internet-facing ARM box managed remotely from devbox.
  # Unlike `server`, there's no yubikey module: its yubioath-flutter GUI isn't
  # cached for aarch64, so it would compile Flutter on the box. There's also no
  # rebuild-config/restore-config, because deploys come from devbox and the box
  # has no /etc/nixos checkout.
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
