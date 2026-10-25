# Media-provisioned PAT → GitHub token for Nix, on the live installer.
#
# A host with a PRIVATE `github:` flake input (tci-cloud's cobblemon-initiative,
# battlestation/devbox's bookkeeper) can't even be evaluated by the installer
# without an `access-tokens` line, and that line lives in Proton Pass (item
# `nix-github-token`, see modules/nix-github-token). So when the install media
# carries a Proton Pass PAT, log in with it and fetch the line:
#
#   - /iso/calapat/pat   — injected into an ISO *file* by `build-pat-iso` (dev
#                          shell). For cloud custom-ISO uploads: a virtual CD-ROM
#                          has no partition table for a CALAPAT partition.
#   - CALAPAT partition  — appended to a USB stick by `flash-iso --with-pat`.
#   - /var/lib/cala-reinstall — carried into the RAM-only installer by
#                          `cala-reinstall` (modules/cala-reinstall), which may
#                          bring the host's own ready-made `nix-access-tokens.conf`
#                          instead, skipping Proton entirely.
#
# The PAT never enters the nix store; every path adds it after the build.
#
# Where the token lands matters: install-cala-m-os's Step Four runs
# `nixos-rebuild` inside `nixos-enter`, which reads the TARGET's nix.conf and
# mounts a fresh /run, but rbinds the live /dev. So the line goes to /dev/shm,
# the live nix.conf `!include`s it, and the install-cala-m-os shim below exports
# it as NIX_USER_CONF_FILES, which the chroot inherits. (`NIX_CONFIG` is no use
# here: install-cala-m-os overwrites it with `tarball-ttl = 0`.) Nix skips a
# missing or unreadable include, so media without a PAT behave as before.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
  mediaDir = config.cala.installer.mediaDir;

  # The token fetcher and the install-cala-m-os shim (./tools.nix), built with
  # this image's media dir baked in as the fallback.
  tools = import ./tools.nix {
    inherit pkgs inputs lib mediaDir;
  };
in {
  options.cala.installer.mediaDir = lib.mkOption {
    type = lib.types.str;
    default = "/iso/calapat";
    description = ''
      Directory holding the install media's `pat` (plus optional `vault`, `item`,
      `field`) or a ready-made `nix-access-tokens.conf`.
    '';
  };

  config = {
    environment.systemPackages = [
      tools.cala-nix-token
      (lib.hiPrio tools.install-cala-m-os)
    ];

    environment.variables = {
      # cala-installer's discover_pat (online hosts) and `proton-secrets login` both
      # honour this; a missing file falls through to the CALAPAT partition.
      PROTON_PASS_PAT_FILE = "${mediaDir}/pat";
      # Where cala-nix-token looks for the PAT / ready-made token — exported so a
      # bundle pulled from the flake by "Update the installer" (built with the
      # default media dir) still reads THIS image's media.
      CALA_INSTALLER_MEDIA_DIR = mediaDir;
    };

    nix.extraOptions = ''
      !include ${tools.tokenFile}
    '';

    # Fetch at boot so cala-installer's pre-install evals (secrets backend, version)
    # already see the token. Type=simple: a oneshot would hold multi-user.target
    # while it waits for the network.
    systemd.services.cala-nix-token = {
      description = "Fetch the GitHub token for private flake inputs via the media's Proton Pass PAT";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${tools.cala-nix-token}/bin/cala-nix-token --wait";
      };
    };
  };
}
