##################################
#                                #
#       Plex Media Server        #
#                                #
##################################
{cala-m-os, ...}: let
  import_users = ["server"];

  machine_type = "VM";
  machine_uuid = "Medium";
in {
  calamoose.version = "0.9.0-beta";

  imports = [
    # Common Core Config
    (import ../_core/default.nix {
      users_list = import_users;
      machine_type = machine_type;
      machine_uuid = machine_uuid;
      extra_user_modules = {server = ["plex"];};
    })

    # Caddy SSL
    ../../services/caddy
  ];

  services.cala-caddy = {
    enable = true;
    reverseProxies = {
      "plex.${cala-m-os.fqdn}" = "localhost:32400";
    };
  };

  # After a teardown + full install this guest's root image is recreated blank,
  # so Plex boots unclaimed with an empty /var/lib/plex ("not an authorized
  # server"). Restore Preferences.xml + the DBs from the NAS backup once, on
  # first boot only — the run-once stamp lives on the wiped root, so an ordinary
  # rebuild skips it. plex-restore stops/starts plex.service itself, so order
  # AFTER it (a Before= would deadlock on the service the script starts).
  calamoose.install.firstBootCommands.plex-restore = {
    run = "plex-restore";
    requiresMounts = ["/mnt/backup"];
    after = ["plex.service"];
  };
}
