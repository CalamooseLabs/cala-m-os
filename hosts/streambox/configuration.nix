##################################
#                                #
#         Stream Box             #
#      NVIDIA RTX Pro 4000       #
#     OBS-only kiosk session     #
#                                #
##################################
{
  config,
  lib,
  pkgs,
  cala-m-os,
  ...
}: let
  import_users = ["streamer"];
  machine_type = "Workstation";
  machine_uuid = "MS-02";
  enable_secrets = false;
in {
  _module.args.enable_secrets = enable_secrets;

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {};
    })
  ];

  networking.hostName = "streambox";

  # Auto-login and launch OBS directly via cage (Wayland kiosk compositor)
  services.greetd.settings = {
    initial_session = {
      command = "${pkgs.cage}/bin/cage -s -- ${config.programs.obs-studio.finalPackage}/bin/obs";
      user = cala-m-os.globals.defaultUser;
    };
    default_session.command = lib.mkForce
      "${pkgs.cage}/bin/cage -s -- ${config.programs.obs-studio.finalPackage}/bin/obs";
  };

  environment.systemPackages = [pkgs.cage];

  # Audio for OBS streaming and monitoring
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
}
