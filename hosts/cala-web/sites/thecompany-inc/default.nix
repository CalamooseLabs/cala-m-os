# The Company, Inc. landing page: one static page linking out to YouTube,
# Twitch and the store (store.thecompany.inc is hosted elsewhere; only the apex
# and www point here), plus two downloads. Converted from the design export to
# plain HTML + CSS: no JavaScript, self-hosted fonts (OFL, public/fonts/OFL.txt)
# and WebP images. DNS lives at Porkbun, not Cloudflare.
#
# Downloads: the files are NOT in this repo. They live in `downloadsDir` on the
# box, and `hub` reaches that folder as ~/downloads. Drop a new build in with
# the file name listed under `downloads`, replacing the old one:
#   scp Cobblemon-Initiative-Demo.mrpack hub@<cala-web>:downloads/
# No rebuild is needed for a new file. The page links to /download/<key>, and
# Caddy serves that file as an attachment, so a click starts the download. Where
# it lands on the visitor's machine is their browser's choice. A missing file is
# a 404. To rename a file or move the folder, change the values below, then
# deploy. The disk is 20 GB, so keep old builds elsewhere.
{
  config,
  cala-m-os,
  ...
}: let
  downloadsDir = "/srv/thecompany-inc/downloads";

  # /download/<key> -> the file of that name in downloadsDir. The page links
  # to these two keys (public/index.html).
  downloads = {
    demo = "Cobblemon-Initiative-Demo.mrpack";
    multiplayer = "Cobblemon-Initiative-Multiplayer.mrpack";
  };

  user = cala-m-os.globals.defaultUser;

  downloadRoute = key: file: ''
    handle /download/${key} {
      root * ${downloadsDir}
      rewrite * "/${file}"
      header Content-Disposition `attachment; filename="${file}"`
      header Cache-Control "no-cache"
      file_server
    }
  '';
in {
  services.caddy.virtualHosts."thecompany.inc".extraConfig = ''
    ${builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs downloadRoute downloads))}
    import static ${./public}
    header Content-Security-Policy "default-src 'none'; style-src 'self'; font-src 'self'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
    header /fonts/* Cache-Control "public, max-age=31536000, immutable"
  '';

  services.caddy.virtualHosts."www.thecompany.inc".extraConfig = ''
    redir https://thecompany.inc{uri} permanent
  '';

  # hub owns the folder (uploads); everyone can read it (Caddy serves it).
  # ~/downloads is only a shortcut: "L" leaves an existing ~/downloads alone.
  systemd.tmpfiles.settings."10-thecompany-downloads" = {
    ${downloadsDir}.d = {
      inherit user;
      group = "users";
      mode = "0755";
    };
    "${config.users.users.${user}.home}/downloads".L.argument = downloadsDir;
  };
}
