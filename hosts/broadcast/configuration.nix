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
  # config,
  # pkgs,
  ...
}: let
  import_users = ["streamer"];
  machine_type = "Workstation";
  machine_uuid = "TRX50-SAGE";
in {
  calamoose.enableSecrets = false;

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

  networking.hostName = "broadcast";

  # Auto-login and launch OBS directly via cage (Wayland kiosk compositor)
  # services.greetd.settings = {
  #   initial_session = {
  #     command = "${pkgs.cage}/bin/cage -s -- ${obsLauncher}";
  #     user = cala-m-os.globals.defaultUser;
  #   };
  #   default_session.command =
  #     lib.mkForce
  #     "${pkgs.cage}/bin/cage -s -- ${obsLauncher}";
  # };

  # environment.systemPackages = [pkgs.cage];

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
}
