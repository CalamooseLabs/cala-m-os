# Websites served by webhost.
#
# Each subdirectory is one site. Its default.nix is a small NixOS module that
# declares the site's Caddy vhost. A static site is one line,
# `import static ${./public}`, which serves public/ with clean URLs (/furnace →
# furnace.html). A site that needs a backend adds its own systemd service
# (plain Python or Node, no deps) next to the vhost and uses `reverse_proxy`.
#
# Directories whose names start with "_" are skipped, so a site can be parked by
# renaming it. Flakes only see git-tracked files: `git add` a new site, and
# every file under its public/, before rebuilding. Otherwise it just isn't
# there.
{
  config,
  options,
  lib,
  pkgs,
  cala-m-os,
  ...
}: let
  siteDirs =
    lib.filterAttrs (name: type: type == "directory" && !lib.hasPrefix "_" name)
    (builtins.readDir ./.);

  # Domains declared by the site modules in this folder. Two sites claiming the
  # same domain (e.g. a copied site dir whose domain wasn't changed) would merge
  # into ONE Caddy block, where the last root silently wins, so refuse it.
  # Assumes the documented plain-attrset form; mkIf/mkMerge-wrapped definitions
  # are skipped.
  siteDomains = lib.concatMap (d: lib.attrNames d.value) (lib.filter
    (d: lib.hasPrefix "${toString ./.}/" d.file && !(d.value ? _type))
    options.services.caddy.virtualHosts.definitionsWithLocations);
  duplicateDomains = lib.unique (lib.filter (n: lib.count (m: m == n) siteDomains > 1) siteDomains);
in {
  imports = map (name: ./${name}) (lib.attrNames siteDirs);

  assertions = [
    {
      assertion = duplicateDomains == [];
      message = "webhost: domain(s) claimed by more than one site in hosts/webhost/sites: ${lib.concatStringsSep ", " duplicateDomains}";
    }
  ];

  services.caddy = {
    enable = true;
    email = cala-m-os.globals.defaultEmail; # Let's Encrypt account / expiry notices
    openFirewall = true; # 80/tcp (ACME + redirect), 443/tcp, 443/udp (HTTP/3)

    # Shared static-site handler: `import static <root>`. Snippets must be
    # defined before they're used, and the module emits extraConfig ahead of
    # the vhosts.
    extraConfig = ''
      (static) {
        root * {args[0]}
        encode zstd gzip
        try_files {path} {path}.html
        file_server
        header {
          X-Content-Type-Options "nosniff"
          Referrer-Policy "strict-origin-when-cross-origin"
          X-Frame-Options "DENY"
        }
      }
    '';
  };

  # The caddy module's only build step is `caddy fmt`, which accepts unknown
  # directives and unbalanced braces. Validate for real, with the service's own
  # caddy binary, so a broken site fails the build rather than the switch. The
  # sandbox can't write /var/log/caddy, so validate a copy whose log paths are
  # moved under $TMPDIR (only the path changes, so `output file … { roll_* }`
  # blocks survive).
  system.checks = [
    (pkgs.runCommand "caddyfile-validate" {nativeBuildInputs = [config.services.caddy.package];} ''
      export HOME=$TMPDIR
      sed -E "s#(output[[:space:]]+file[[:space:]]+)/#\1$TMPDIR/logs/#" ${config.services.caddy.configFile} > Caddyfile
      caddy validate --adapter caddyfile --config Caddyfile
      touch $out
    '')
  ];
}
