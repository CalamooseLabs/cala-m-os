{
  cala-m-os,
  inputs,
  lib,
  pkgs,
  ...
}: let
  user = cala-m-os.globals.defaultUser;

  # Keep only host=ip entries: drop the subnet/gateway/prefixLength metadata keys
  # (prefixLength is also an int, so isString filters it too).
  meta = ["subnet" "prefixLength" "gateway"];
  hostsIn = subnet: lib.filterAttrs (n: v: !(builtins.elem n meta) && builtins.isString v) subnet;

  fleet = (hostsIn cala-m-os.ip.lab) // (hostsIn cala-m-os.ip.studio);

  # One line per host: "name  user@name  fallback-ip". moosewire tries the
  # hostname first (future DNS / tailscale) and falls back to the baked IP when
  # it doesn't resolve or connect — the fleet's dns-then-ip idiom (cf. remote-kvm).
  line = name: ip: "${name}  ${user}@${name}  ${ip}";
  body = lib.concatStringsSep "\n" (lib.mapAttrsToList line fleet);

  hostsFile = ''
    # moosewire host list — generated from settings.nix (cala-m-os.ip.*).
    # columns: name  [user@]host  fallback-ip   (whitespace separated)
    ${body}
  '';
in {
  # moosewire (antlers): dual-pane SSH/SCP file mover. Left pane = local, right
  # pane = a fleet host reached over ONE ssh ControlMaster connection (one
  # Yubikey touch; copies reuse it). The remote needs nothing but sshd +
  # coreutils. Launch `moosewire` for the host picker or `moosewire <name>` to
  # connect directly; press ? in the TUI for keys.
  home.packages = [inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.moosewire];

  # The baked host list, generated from the fleet's IP table.
  xdg.configFile."moosewire/hosts".text = hostsFile;
}
