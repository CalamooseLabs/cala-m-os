# unifi-protect-monitor — the UniFi Protect camera-wall web service
# (services.unifi-protect-monitor, from the antlers flake). Enrolled onto a host by adding
# "unifi-protect-monitor" to a user's module list; here it rides the `server` user of the
# `security` microVM guest (see hosts/security/configuration.nix). The service is host-level.
#
# Secrets: on the guest the integration API key and the recorded-playback admin password
# are decrypted on the homelab HOST (agenix) and shared in at /run/hostsecrets/* by the
# vm-manager virtiofs share (see services/vm-manager/default.nix) — declared in
# hosts/homelab/secrets/{secrets.nix,default.nix}.
{inputs, ...}: {
  imports = [inputs.antlers.nixosModules.unifi-protect-monitor];

  services.unifi-protect-monitor = {
    enable = true;

    # The local UniFi Protect console.
    consoleIP = "10.10.10.251";

    # Integration-API X-API-KEY (read at runtime, never in the store).
    apiKeyFile = "/run/hostsecrets/protect-api-key";

    # LAN-only web UI on http://<guest>:8460 — passwordless on the trusted LAN. Add
    # passwordFile (another /run/hostsecrets/* secret) to gate it further.
    openFirewall = true;
    localNetworkOnly = true;

    # Recorded-video playback (opt-in): the internal recorded-video API needs a UniFi-OS
    # LOCAL-admin session (the X-API-KEY does not work there).
    recordings = {
      enable = true;
      username = "unifi_protect_monitor";
      passwordFile = "/run/hostsecrets/protect-admin-password";
    };
  };
}
