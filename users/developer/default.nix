{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  modules = [
    "agenix"
    "bash"
    "claude-code"
    "git"
    "github-repo-puller"
    "gpg"
    "gpg-key-import"
    "nh"
    "openssh"
    "yubikey"
    "zed-editor"
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
