# Home-manager config owned by the `broadcast` HOST (its streaming role + brand
# identity) rather than the TRX50-SAGE machine (hardware). Wired into home-manager
# via `home-manager.sharedModules` in ./configuration.nix, alongside the machine's
# own home.nix. Options are declared by modules/obs-studio/home.nix (opted into by
# the streamer user).
#
# seedSource auto-wires once a real baseline (basic/ or global.ini) is committed;
# until then it stays null and OBS starts fresh. `obs-config-snapshot` keys off
# repoPath, so it can capture that first baseline even while seedSource is null.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # OBS's own obs-websocket server config, seeded with auth DISABLED. The websocket
  # is localhost-only in practice — port 4455 is not opened in the firewall (only
  # 9998/SRT is) — and this is a single-user box, so Companion connects over
  # loopback with no password. That keeps the Companion db's blank connection
  # password working with zero secret to manage. server_enabled=true so Companion
  # can connect on a fresh box without enabling the server by hand. first_load=false
  # so OBS doesn't auto-generate a password (it only does so on a true first load).
  obsWebsocketConfig = pkgs.writeText "obs-websocket-config.json" (builtins.toJSON {
    alerts_enabled = false;
    auth_required = false;
    first_load = false;
    server_enabled = true;
    server_port = 4455;
  });
in {
  calamoose.obs = {
    seedSource = let
      p = ./obs;
    in
      if builtins.pathExists (p + "/basic") || builtins.pathExists (p + "/global.ini")
      then p
      else null;
    repoPath = "/etc/nixos/hosts/broadcast/obs";

    # Media the scene sources reference by absolute $HOME path. The TheCalamoose
    # scenes point at /home/hub/{brb,starting}.mp4 + /home/hub/overlay.html, so
    # those files must exist there on a fresh box or the overlays render black.
    # Assets live once in modules/obs-kiosk/assets/<brand>/. This box is primarily
    # The Company but also runs TheCalamoose for testing — add a "thecompany/…"
    # destination set once those scenes/overlays exist so the two brands never
    # collide at the same $HOME path.
    homeAssets = {
      "brb.mp4" = ../../modules/obs-kiosk/assets/thecalamoose/brb.mp4;
      "starting.mp4" = ../../modules/obs-kiosk/assets/thecalamoose/starting.mp4;
      "overlay.html" = ../../modules/obs-kiosk/assets/thecalamoose/overlay.html;
    };
  };

  # Seed OBS's obs-websocket config copy-if-absent (auth disabled — see
  # obsWebsocketConfig above). Non-secret, so it's a plain committed store file; the
  # machine owns it after the first activation, and OBS starts its websocket server
  # with no auth so Companion connects passwordless over loopback.
  home.activation.seedObsWebsocket = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ws="${config.xdg.configHome}/obs-studio/plugin_config/obs-websocket/config.json"
    if [ ! -e "$ws" ]; then
      run mkdir -p "$(dirname "$ws")"
      run ${pkgs.coreutils}/bin/install -m 0644 ${obsWebsocketConfig} "$ws"
    fi
  '';
}
