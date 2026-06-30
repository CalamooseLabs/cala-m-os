# Shared obs-kiosk launcher — deduplicated from modules/niri and users/streamer
# (both imported the same script). PRIME-offloads OBS (compositing + NVENC) onto
# the discrete NVIDIA RTX PRO 4000 while the AMD GPU drives the desktop +
# DisplayLink teleprompter. This is welded to that dual-GPU studio box (hardcoded
# /run/opengl-driver paths + NVIDIA glvnd), so it stays in the config rather than
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
}: {
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
          # Ask the compositor to spawn obs-kiosk (no flag → the PRIME launch below)
          # in its own environment. hyprctl returns as soon as the spawn is
          # *accepted*, not when OBS is up — and a crash often leaves a stale lock
          # that makes the relaunched OBS exit at once — so confirm by polling for
          # the process and report real success/failure instead of a misleading "ok".
          # Target the session user (the SSH login may be root); they own the runtime
          # dir we found. Match the obs-studio store path with -f so we never match
          # this obs-kiosk process itself.
          session_user="$(stat -c %U "$XDG_RUNTIME_DIR")"
          if ! ${config.programs.hyprland.package}/bin/hyprctl dispatch exec obs-kiosk; then
            echo "obs-kiosk: hyprctl dispatch failed for instance $HYPRLAND_INSTANCE_SIGNATURE" >&2
            exit 1
          fi
          echo "obs-kiosk: dispatched into Hyprland ($HYPRLAND_INSTANCE_SIGNATURE) as $session_user; waiting for OBS..." >&2
          for _ in $(seq 1 15); do
            if pgrep -u "$session_user" -f obs-studio >/dev/null 2>&1; then
              echo "obs-kiosk: OBS is up" >&2
              exit 0
            fi
            sleep 1
          done
          echo "obs-kiosk: OBS did not come up within 15s — check for a stale lock or missing GL paths (try: pgrep -u $session_user -f obs-studio)" >&2
          exit 1
        fi
        if [ "$#" -gt 0 ]; then
          echo "obs-kiosk: unknown argument '$1' (use --hypr/--current to relaunch into the running Hyprland session)" >&2
          exit 2
        fi

        export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

        # PRIME render offload: run OBS (compositing + NVENC) on the NVIDIA RTX PRO
        # 4000, while the AMD GPU drives the desktop + DisplayLink teleprompter.
        # NVENC itself works regardless; this keeps OBS's own GL rendering off the
        # weak Arc and avoids a cross-GPU readback.
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        nvjson=$(ls /run/opengl-driver/share/glvnd/egl_vendor.d/*nvidia*.json 2>/dev/null | head -1 || true)
        if [ -n "$nvjson" ]; then export __EGL_VENDOR_LIBRARY_FILENAMES="$nvjson"; fi

        exec ${config.programs.obs-studio.finalPackage}/bin/obs
      '')
    ];
  };
}
