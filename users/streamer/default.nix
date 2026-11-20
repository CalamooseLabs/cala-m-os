{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  # Headless (broadcast): the three stream services plus what an SSH or
  # console login uses. No compositor, terminal, browser or theming modules;
  # that host has no session to show them in.
  modules = [
    # Needed although the host's backend is the online one: modules/secrets
    # (always imported by _core) defines age.* under a false mkIf, and that
    # still requires the options to exist. Nothing is installed by it there.
    "agenix"
    "bash"
    "chatcards"
    "cobblemon-overlay"
    "moosefetch"
    "multichat"
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
