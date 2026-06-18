##################################
#                                #
#          Stream Box            #
#       NVIDIA RTX Pro 4000      #
#      Blackmagic Quad HDMI      #
#             OBS                #
#     Davinci Resolve Studio     #
#                                #
##################################
{
  config,
  pkgs,
  lib,
  initialInstallMode,
  ...
}: let
  import_users = ["streamer"];
  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";

  # OBS's obs-nvenc helper does a bare dlopen("libnvidia-encode.so.1"), which
  # isn't on any ldconfig path on NixOS. Expose the driver libs so NVENC probes.
  # niri spawns this at startup (see users/streamer/niri.kdl).
  obsLauncher = pkgs.writeShellScriptBin "obs-kiosk" ''
    export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec ${config.programs.obs-studio.finalPackage}/bin/obs "$@"
  '';

  # Hitting the power button should let OBS finalize any active recording/stream
  # before the machine powers off, rather than yanking power mid-write.
  gracefulPowerOff = pkgs.writeShellScript "graceful-poweroff" ''
    # Politely ask OBS to quit (it stops recording/streaming and saves on SIGINT).
    ${pkgs.procps}/bin/pkill -INT -x obs || true

    # Give OBS up to 20s to flush and exit before powering off.
    for _ in $(${pkgs.coreutils}/bin/seq 1 20); do
      ${pkgs.procps}/bin/pgrep -x obs > /dev/null || break
      ${pkgs.coreutils}/bin/sleep 1
    done

    ${pkgs.systemd}/bin/systemctl poweroff
  '';
in {
  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

  config = lib.mkMerge [
    {
      calamoose.enableSecrets = false;

      networking.hostName = "broadcast";
    }

    # Workstation-only runtime config. Skipped during the minimal installer pass
    # (INITIAL_INSTALL_MODE=1), where programs.obs-studio isn't enabled and its
    # finalPackage is null — building obsLauncher then fails to evaluate.
    (lib.mkIf (!initialInstallMode) {
      # niri (enabled via the streamer user's modules) auto-logs in through greetd
      # and spawns OBS at startup. obs-kiosk wraps OBS with the NVENC library path.
      environment.systemPackages = [obsLauncher];

      # Power button: gracefully stop OBS, then power off. Let logind ignore the key
      # so acpid can run the graceful handler instead of an instant poweroff.
      services.logind.settings.Login.HandlePowerKey = "ignore";
      services.acpid = {
        enable = true;
        handlers.power-button = {
          event = "button/power.*";
          action = "${gracefulPowerOff}";
        };
      };

      # Audio for OBS streaming and monitoring
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
        jack.enable = true;
      };

      services.pulseaudio.enable = false;

      boot.extraModprobeConfig = ''
        options snd_usb_audio vid=0x1235 pid=0x8218 device_setup=1
      '';
    })
  ];
}
