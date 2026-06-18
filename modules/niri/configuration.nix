{
  config,
  pkgs,
  ...
}: {
  programs.niri.enable = true;

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "obs-kiosk" ''
      set -eux
      export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

      # PRIME render offload: run OBS (compositing + NVENC) on the NVIDIA RTX PRO
      # 4000, while the Arc A310 drives niri + the DisplayLink teleprompter. NVENC
      # itself works regardless; this just keeps OBS's own GL rendering off the
      # weak Arc and avoids a cross-GPU readback.
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      nvjson=$(ls /run/opengl-driver/share/glvnd/egl_vendor.d/*nvidia*.json 2>/dev/null | head -1 || true)
      if [ -n "$nvjson" ]; then export __EGL_VENDOR_LIBRARY_FILENAMES="$nvjson"; fi

      exec ${config.programs.obs-studio.finalPackage}/bin/obs
    '')
  ];

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Login Service
  services.greetd.settings.default_session.command = "niri &> /dev/null";
}
