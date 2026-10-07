# Shared obs-kiosk launcher — deduplicated from modules/niri and users/streamer
# (both imported the same script). Runs OBS on the AMD GPU (same renderer as the
# compositor, so the preview + capture sources import cleanly) and lets NVENC
# encode on the NVIDIA card via libnvidia-encode. This is welded to that studio
# box (hardcoded /run/opengl-driver path), so it stays in the config rather than
# moving to the portable antlers collection.
#
# Usage:
#   obs-kiosk            launch OBS here (the autostart path: a graphical session
#                        already provides the Wayland/DBUS/portal environment).
#   obs-kiosk --hypr     relaunch OBS into the already-running Hyprland session —
#                        for restarting a crashed OBS over SSH. Rather than exec
#                        OBS in the SSH shell (wrong user, no session env, dies on
#                        disconnect), it asks the live compositor to spawn the
#                        env-bare obs-kiosk itself, so OBS inherits the full session
#                        environment, runs as the session user, and outlives SSH.
#                        It then waits and reports whether OBS actually came up.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # pgrep/pkill selector for the MAIN obs process, by kernel name (comm) —
  # never by argv. The wrapper chain (wrapOBS → the nosync wrapProgram in
  # modules/obs-studio → obs's own C wrapper) loses `exec -a` at the shebang
  # hop, so the live process's argv0 is …-wrapped-obs-studio-nosync/bin/
  # .obs-wrapped__, which the old argv pattern anchored on bin/obs never
  # matched. comm is the exec'd binary's own name: ".obs-wrapped" (or "obs"
  # unwrapped). Helpers can't match: their comm truncates to ".obs-ffmpeg-mux" /
  # ".obs-nvenc-test" (15 chars) and CEF's is "obs-browser-pag".
  obsProc = "-x '\\.?obs(-wrapped)?'";
in {
  # Only ship obs-kiosk where OBS is actually configured. niri is also used on
  # boxes without OBS (the ephemeral lab host's `void` user); gating on
  # programs.obs-studio.enable keeps config.programs.obs-studio.finalPackage
  # (null when OBS is off) from being coerced into the script there.
  config = lib.mkIf config.programs.obs-studio.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "obs-kiosk" ''
        set -eux

        # --hypr / --current: hand off to the running Hyprland compositor so it
        # spawns OBS in-session (see header). Usable over SSH to relaunch a crashed
        # OBS. A direct `exec obs` from an SSH shell would run as the wrong user
        # with none of the session's graphical env (Wayland socket, DBUS, the
        # xdg-desktop-portal screen-capture backend) and would die on disconnect.
        if [ "''${1:-}" = "--hypr" ] || [ "''${1:-}" = "--current" ]; then
          set +x  # the loops/poll below would flood an SSH operator with xtrace;
                  # print our own status lines instead.
          shopt -s nullglob
          # Locate a live Hyprland control socket. Prefer this login's runtime dir
          # (SSH as the session user); otherwise scan every user's (SSH as root).
          # Hyprland keeps its sockets at $XDG_RUNTIME_DIR/hypr/<signature>/.
          sockdir=""
          for base in "''${XDG_RUNTIME_DIR:-}" /run/user/*; do
            [ -n "$base" ] || continue
            for d in "$base"/hypr/*/; do
              if [ -S "''${d}.socket.sock" ]; then sockdir="$d"; break 2; fi
            done
          done
          if [ -z "$sockdir" ]; then
            echo "obs-kiosk: no running Hyprland instance found (searched \$XDG_RUNTIME_DIR and /run/user/*)" >&2
            exit 1
          fi
          # hyprctl finds the instance via these two; export them for the cross-user
          # (root) case where the SSH session's own values point elsewhere.
          XDG_RUNTIME_DIR="$(dirname "$(dirname "$sockdir")")"; export XDG_RUNTIME_DIR
          HYPRLAND_INSTANCE_SIGNATURE="$(basename "$sockdir")"; export HYPRLAND_INSTANCE_SIGNATURE
          # Relaunch is a no-op while OBS is up: dispatching a second instance
          # would hit OBS's "already running — launch anyway?" dialog, which is
          # exactly the kind of modal this kiosk path exists to avoid. Matches
          # the session user's OBS the same way the wait loop below does.
          session_user="$(stat -c %U "$XDG_RUNTIME_DIR")"
          if pgrep -u "$session_user" ${obsProc} >/dev/null 2>&1; then
            echo "obs-kiosk: OBS is already running — nothing to do" >&2
            exit 0
          fi
          # Likewise while a launch is still waiting on its stream keys (see the
          # obs-stream-keys step below): that obs-kiosk will exec OBS shortly.
          if pgrep -u "$session_user" -x obs-stream-keys >/dev/null 2>&1; then
            echo "obs-kiosk: an OBS launch is already in progress (waiting for stream keys) — nothing to do" >&2
            exit 0
          fi
          # Ask the compositor to spawn obs-kiosk (no flag → the PRIME launch below)
          # in its own environment. hyprctl returns as soon as the spawn is
          # *accepted*, not when OBS is up — and a crash often leaves a stale lock
          # that makes the relaunched OBS exit at once — so confirm by polling for
          # the process and report real success/failure instead of a misleading "ok".
          # Target the session user (the SSH login may be root); they own the runtime
          # dir we found. Seconds spent while the launch waits on its stream keys
          # (up to 90s, see below) don't count against the 15s.
          if ! ${config.programs.hyprland.package}/bin/hyprctl dispatch exec obs-kiosk; then
            echo "obs-kiosk: hyprctl dispatch failed for instance $HYPRLAND_INSTANCE_SIGNATURE" >&2
            exit 1
          fi
          echo "obs-kiosk: dispatched into Hyprland ($HYPRLAND_INSTANCE_SIGNATURE) as $session_user; waiting for OBS..." >&2
          waited=0
          for _ in $(seq 1 120); do
            if pgrep -u "$session_user" ${obsProc} >/dev/null 2>&1; then
              echo "obs-kiosk: OBS is up" >&2
              exit 0
            fi
            if ! pgrep -u "$session_user" -x obs-stream-keys >/dev/null 2>&1; then
              waited=$((waited + 1))
              [ "$waited" -le 15 ] || break
            fi
            sleep 1
          done
          echo "obs-kiosk: OBS did not come up — check for a stale lock or missing GL paths (try: pgrep -u $session_user -x .obs-wrapped)" >&2
          exit 1
        fi
        if [ "$#" -gt 0 ]; then
          echo "obs-kiosk: unknown argument '$1' (use --hypr/--current to relaunch into the running Hyprland session)" >&2
          exit 2
        fi

        # OBS 32 removed --disable-shutdown-check, so a crashed previous session
        # (stale run_* files under .sentinel/ — OBS clears them only on a clean
        # exit) would greet the next launch with the blocking "did not properly
        # shut down… Run in Safe Mode?" dialog — a kiosk killer. Clear stale
        # sentinels before launching, but only when no OBS is running: a live
        # instance owns its own run_ file and deleting it would blind real
        # crash detection.
        if ! pgrep -u "$(id -un)" ${obsProc} >/dev/null 2>&1; then
          rm -f "''${XDG_CONFIG_HOME:-$HOME/.config}/obs-studio/.sentinel/run_"* 2>/dev/null || true
        fi

        # Stream keys (calamoose.obs.streamKeys in modules/obs-studio, where a
        # host configures them): inject now, while OBS is still closed — OBS
        # reads keys only at launch and the Aitum plugins rewrite their config
        # on exit. --wait covers a fresh box whose Proton secrets are still being
        # fetched (they arrive after network-online); an injected key persists in
        # the OBS config, so later boots don't wait. May delay the launch (≤90s,
        # only until the boot-time fetch finishes); never prevents it.
        if command -v obs-stream-keys >/dev/null 2>&1; then
          obs-stream-keys --wait 90 || true
          # Another launcher may have started OBS during that wait — don't
          # stack a second instance (and its "already running" modal) on it.
          if pgrep -u "$(id -un)" ${obsProc} >/dev/null 2>&1; then
            echo "obs-kiosk: OBS was started meanwhile — nothing to do" >&2
            exit 0
          fi
        fi

        export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

        # Render OBS on the AMD GPU — the SAME GPU the compositor renders on — so
        # OBS's preview surface and screen-capture sources stay same-vendor and
        # import into the AMD-composited desktop cleanly. (The old
        # __NV_PRIME_RENDER_OFFLOAD made OBS render on the NVIDIA card while the
        # desktop renders on AMD; those nvidia buffers could not be imported back to
        # the AMD compositor → black OBS preview and black capture sources — the
        # same cross-vendor wall that blocks nvidia→evdi.) NVENC is unaffected: OBS's
        # NVENC encoder talks to the NVIDIA card directly via libnvidia-encode (kept
        # on LD_LIBRARY_PATH above), independent of which GPU OBS renders on — so
        # hardware encoding stays available while the preview works.

        exec ${config.programs.obs-studio.finalPackage}/bin/obs
      '')

      # Power off, but let OBS die with dignity first. On OBS 32+, SIGTERM is a
      # GRACEFUL shutdown (saves config, stops outputs, clears the .sentinel
      # crash marker) and — unlike SIGINT — bypasses the "OBS is still active"
      # confirm dialog, so it works headless/mid-stream. Powering off around a
      # running OBS instead kills compositor + OBS together, OBS loses the race,
      # the sentinel survives, and the next launch gets the Safe Mode popup.
      # pkill/pgrep target the MAIN process only (obsProc, by comm). They must
      # not match obs-ffmpeg-mux (TERM would kill a replay-buffer save mid-write
      # and truncate the file — OBS stops it cleanly itself), obs-nvenc-test,
      # or the CEF helpers.
      # Wired to the physical power button on broadcast (logind ignores the key,
      # Hyprland bindl execs this) and to the waybar power pill there.
      (pkgs.writeShellScriptBin "obs-safe-poweroff" ''
        if pkill -TERM ${obsProc} 2>/dev/null; then
          # up to 20s for stream/recording teardown + config write; if OBS is
          # truly hung we power off anyway and let systemd do the killing
          for _ in $(seq 1 40); do
            pgrep ${obsProc} >/dev/null 2>&1 || break
            sleep 0.5
          done
        fi
        exec systemctl poweroff
      '')
    ];
  };
}
