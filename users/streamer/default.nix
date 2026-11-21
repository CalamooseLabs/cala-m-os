{isDefaultUser, ...}: let
  uuid = baseNameOf (toString ./.);

  # Headless (broadcast): mailroom and the three stream services beside it,
  # plus what an SSH or console login uses. No compositor, terminal, browser
  # or theming modules; that host has no session to show them in.
  modules = [
    # Needed although the host's backend is the online one: modules/secrets
    # (always imported by _core) defines age.* under a false mkIf, and that
    # still requires the options to exist. Nothing is installed by it there.
    "agenix"
    "bash"
    # For the SSH login that administers the box: a look at what the machine
    # is doing, git for the /etc/nixos checkout it rebuilds from, an editor.
    # Not nh, rebuild-config or restore-config, although the server profile
    # carries all three and the other headless ones nh: they build as the
    # user who calls them (both scripts run `nh os switch`), and on this
    # host only ROOT's nix holds the token for the private mailroom input
    # (modules/nix-github-token) — rebuilds here are `sudo nixos-rebuild`, with
    # `boot` rather than `switch` when the NVIDIA driver changes (hosts/
    # broadcast). nh would also take over the garbage collection that host
    # schedules for itself.
    "btop"
    "chatcards"
    "cobblemon-overlay"
    "git"
    "mailroom"
    "moosefetch"
    "multichat"
    "neovim"
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
