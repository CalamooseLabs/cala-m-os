##################################
#                                #
#   UniFi Protect Camera Wall    #
#                                #
##################################
# A microVM guest on homelab (declared in hosts/homelab/vms.nix) that runs the UniFi
# Protect camera-wall web service. It streams (ffmpeg audio-transcode + video-copy) and
# proxies recorded clips — light CPU, no local footage storage (recordings live on the
# console). Reaches the console at 10.10.10.251 over the lab bridge; its API key + local-
# admin password arrive from the homelab host at /run/hostsecrets/* (see the module).
{...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "X-Small";
in {
  calamoose.version = "0.9.0-beta";

  imports = [
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      # Enrolls services.unifi-protect-monitor on THIS guest only (not the shared server user).
      extra_user_modules = {server = ["unifi-protect-monitor"];};
    })
  ];
}
