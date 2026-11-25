# The Company, Inc. landing page: one static page linking out to YouTube,
# Twitch and the store (store.thecompany.inc is hosted elsewhere; only the apex
# and www point here). Converted from the design export to plain HTML + CSS:
# no JavaScript, self-hosted fonts (OFL, public/fonts/OFL.txt) and WebP images.
# DNS lives at Porkbun, not Cloudflare.
{
  services.caddy.virtualHosts."thecompany.inc".extraConfig = ''
    import static ${./public}
    header Content-Security-Policy "default-src 'none'; style-src 'self'; font-src 'self'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
    header /fonts/* Cache-Control "public, max-age=31536000, immutable"
  '';

  services.caddy.virtualHosts."www.thecompany.inc".extraConfig = ''
    redir https://thecompany.inc{uri} permanent
  '';
}
