# The Wayland kiosk viewer (Chromium in cage) for the UniFi Protect camera wall — the
# "program" half of unifi-protect-monitor. Uses the antlers `programs.unifi-protect-viewer`
# home-manager module so a BARE `unifi-protect-viewer` opens the defaults below; runtime
# `--server`/`--cameras` still override.
#
#   unifi-protect-viewer                         # opens the default server (dashboard)
#   unifi-protect-viewer --cameras "Nursery"     # chrome-free, audio-on baby-monitor view
#   unifi-protect-viewer --server http://other   # override the server
{inputs, ...}: {
  imports = [inputs.antlers.homeManagerModules.unifi-protect-viewer];

  programs.unifi-protect-viewer = {
    enable = true;
    server = "http://10.10.10.20:8460"; # the homelab `security` VM
    # cameras = ["Nursery"]; # set to default straight into a chrome-free multiview
  };
}
