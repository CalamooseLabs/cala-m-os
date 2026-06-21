# Shared obs-kiosk launcher — deduplicated from modules/niri and users/streamer
# (both imported the same script). PRIME-offloads OBS (compositing + NVENC) onto
# the discrete NVIDIA RTX PRO 4000 while the Arc A310 drives the desktop +
# DisplayLink teleprompter. This is welded to that dual-GPU studio box (hardcoded
# /run/opengl-driver paths + NVIDIA glvnd), so it stays in the config rather than
# moving to the portable antlers collection.
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
        export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

        # PRIME render offload: run OBS (compositing + NVENC) on the NVIDIA RTX PRO
        # 4000, while the Arc A310 drives the desktop + DisplayLink teleprompter.
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
