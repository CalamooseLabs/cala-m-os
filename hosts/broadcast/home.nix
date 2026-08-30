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
    # scenes point at /home/hub/assets/thecalamoose/{brb,starting}.mp4 +
    # overlay.html (the committed scene JSON references these exact paths), so
    # those files must exist there on a fresh box or the overlays render black.
    # Assets live once in modules/obs-kiosk/assets/<brand>/; the per-brand
    # assets/<brand>/ destination keeps brands from colliding at the same $HOME
    # path. This box is primarily The Company but also runs TheCalamoose for
    # testing — add an "assets/thecompany/…" set once those scenes exist.
    homeAssets = {
      "assets/thecalamoose/brb.mp4" = ../../modules/obs-kiosk/assets/thecalamoose/brb.mp4;
      "assets/thecalamoose/starting.mp4" = ../../modules/obs-kiosk/assets/thecalamoose/starting.mp4;
      "assets/thecalamoose/overlay.html" = ../../modules/obs-kiosk/assets/thecalamoose/overlay.html;
    };
  };

  # Physical power button → clean OBS exit → poweroff. logind ignores the key
  # (see ./configuration.nix); Hyprland catches XF86PowerOff instead and runs
  # obs-safe-poweroff (modules/obs-kiosk), which SIGTERMs OBS — a graceful
  # shutdown on OBS 32+ that clears the crash sentinel — waits for it to exit,
  # then powers off. Result: no "did not shut down properly / Safe Mode?"
  # dialog on the next boot. bindl, so it works even on a locked session.
  wayland.windowManager.hyprland.settings.bindl = [
    ", XF86PowerOff, exec, obs-safe-poweroff"
  ];

  cala.waybar = {
    # No rofi (powermenu) on this box; a click on the bar's power pill does the
    # same safe OBS-then-poweroff as the physical button. Via hyprctl dispatch
    # so the script runs inside the logind session scope — `systemctl poweroff`
    # from the bar's own context (user@.service, no session) can trip polkit's
    # auth_admin instead of the active-session allow.
    powerCommand = "hyprctl dispatch exec obs-safe-poweroff";
    # Quick-launch pills (left of the clock). obs-kiosk --hypr relaunches a
    # crashed OBS into the running session and no-ops if OBS is already up.
    # Companion/Multichat admin UIs are loopback ports; chromium-ephemeral is
    # the only browser on this box (the chromium module ships no plain
    # `chromium`) — throwaway profile is fine for these auth-less local UIs.
    quickLaunch = [
      {
        id = "obs";
        glyph = "";
        command = "obs-kiosk --hypr";
        tooltip = "Relaunch OBS (no-op if already running)";
      }
      {
        id = "companion";
        glyph = "";
        command = "chromium-ephemeral http://localhost:8000";
        tooltip = "Bitfocus Companion admin";
      }
      {
        id = "multichat";
        glyph = "";
        command = "chromium-ephemeral http://localhost:8081";
        tooltip = "Multichat";
      }
    ];
  };

  # One-shot migration for the assets-dir rename: the live box was seeded with
  # machine-owned copies at the OLD flat paths (/home/hub/{brb,starting}.mp4,
  # overlay.html) that may carry on-box tweaks; carry them (drift included) to
  # the new per-brand paths BEFORE the copy-if-absent seed runs, so the seed
  # skips them and no orphans are left behind. No-ops everywhere else.
  home.activation.migrateObsHomeAssets = lib.hm.dag.entryBetween ["seedObsHomeAssets"] ["writeBoundary"] ''
    for f in brb.mp4 starting.mp4 overlay.html; do
      if [ -e "$HOME/$f" ] && [ ! -e "$HOME/assets/thecalamoose/$f" ]; then
        run mkdir -p "$HOME/assets/thecalamoose"
        run mv "$HOME/$f" "$HOME/assets/thecalamoose/$f"
      fi
    done
  '';

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
