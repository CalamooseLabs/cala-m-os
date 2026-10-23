# Theisen HVAC dashboard: three static pages of links to the plant's LAN
# thermostats. The http://192.168.11.x links only work from the plant network.
# Moved off Deno Deploy; the old oak main.ts did nothing except serve these
# files. output.css is prebuilt Tailwind v3 output: rebuild it if the markup
# starts using new classes.
{
  services.caddy.virtualHosts."hvac.calamooselabs.com".extraConfig = ''
    import static ${./public}
    # No JavaScript. The inline <style> tags live inside the SVG logos.
    header Content-Security-Policy "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
  '';
}
