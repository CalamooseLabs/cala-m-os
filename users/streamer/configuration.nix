{username, ...}: {
  config,
  pkgs,
  ...
}: {
  # OBS kiosk launcher (relocated from the niri module for the Hyprland switch).
  # PRIME-offloads OBS onto the RTX PRO 4000 so compositing + NVENC run there,
  # while the Arc A310 drives the desktop + DisplayLink teleprompter.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "obs-kiosk" ''
      set -eux
      export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      nvjson=$(ls /run/opengl-driver/share/glvnd/egl_vendor.d/*nvidia*.json 2>/dev/null | head -1 || true)
      if [ -n "$nvjson" ]; then export __EGL_VENDOR_LIBRARY_FILENAMES="$nvjson"; fi
      exec ${config.programs.obs-studio.finalPackage}/bin/obs
    '')
  ];

  users.users."${username}" = {
    extraGroups = [
      "wheel"
      "networkmanager"
      "disk"
      "video"
      "audio"
      "render"
      "input"
      "plugdev"
    ];

    openssh.authorizedKeys.keyFiles = [
      ./public_keys/id_ed25519_sk.pub
      ./public_keys/backup_id_ed25519_sk.pub
    ];
  };

  security.sudo.extraRules = [
    {
      users = ["${username}"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  systemd.services.agenix.after = [
    "basic.target"
  ];
}
