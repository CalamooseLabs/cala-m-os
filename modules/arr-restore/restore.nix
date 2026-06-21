# Shared helper that builds an `<app>-restore` admin command for a Servarr app.
#
# Mirrors modules/plex/configuration.nix's plexRestore: a writeShellApplication
# wrapping ./restore.sh, with the per-app parameters injected as shell variables
# so the one script serves sonarr / radarr / prowlarr alike.
#
# Usage (from a module):
#   arrRestore = import ../arr-restore/restore.nix {inherit pkgs lib;};
#   environment.systemPackages = [
#     (arrRestore {
#       app = "sonarr";
#       db = "sonarr.db";
#       dataDir = "/var/lib/sonarr/.config/NzbDrone";
#       port = 8989;
#       backup = "/mnt/backups/sonarr";
#     })
#   ];
{
  pkgs,
  lib,
}: {
  app, # short name, e.g. "sonarr" (also names the command: sonarr-restore)
  db, # database filename inside the backup zip, e.g. "sonarr.db"
  dataDir, # the app's -data dir (services.<app>.dataDir)
  port, # web/API port, used for the /ping health check
  backup, # mounted NAS backup share the app writes its backups to
  service ? "${app}.service",
}:
pkgs.writeShellApplication {
  name = "${app}-restore";
  runtimeInputs = with pkgs; [coreutils findutils util-linux systemd curl gnugrep gnused unzip];
  text =
    ''
      APP=${lib.escapeShellArg app}
      DB=${lib.escapeShellArg db}
      DATADIR=${lib.escapeShellArg dataDir}
      SERVICE=${lib.escapeShellArg service}
      PORT=${toString port}
      BACKUP=${lib.escapeShellArg backup}
    ''
    + builtins.readFile ./restore.sh;
}
