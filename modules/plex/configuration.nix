{
  cala-m-os,
  inputs,
  pkgs,
  ...
}: let
  # plex-backup/plex-restore now ship from the antlers scripts collection. The
  # script defaults (data dir /var/lib/plex, backup /mnt/backup, plex:plex,
  # plex.service, :32400, retention 7) match this host, so no overrides needed.
  plexBackup = inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.plex-backup;
in {
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  services.plex = {
    enable = true;
    openFirewall = true;
  };

  # The plex daemon runs as the dedicated `plex` user, which upstream adds to no
  # supplementary groups. Render nodes are 0666 so /dev/dri/renderD* is already
  # reachable, but grant render+video explicitly so HW transcode on the passed-
  # through Arc B50 cannot be blocked by a non-default render-node permission.
  users.users.plex.extraGroups = ["render" "video"];

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/media/movies" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.media.movies}";
    fsType = "nfs";
  };

  fileSystems."/media/tv-shows" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.media.tv-shows}";
    fsType = "nfs";
  };

  # nofail: a missing NAS must not wedge the guest's boot; plex-backup and the
  # first-boot plex-restore wait for the share via RequiresMountsFor instead.
  fileSystems."/mnt/backup" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.plex}";
    fsType = "nfs";
    options = ["nofail"];
  };

  # Upstream orders plex.service only after network.target, i.e. it can start
  # before the NFS library mounts are up and see /media/* empty. With "Empty
  # trash automatically after every scan" (Plex's default) a scan in that
  # window would purge the whole library from the database. Hard-order Plex
  # after its library mounts so it never runs against an empty library.
  systemd.services.plex.unitConfig.RequiresMountsFor = ["/media/movies" "/media/tv-shows"];

  # Admin tooling: snapshot the server (plex-backup), and restore it after a
  # rebuild (plex-restore). Installed via the antlers scripts module.
  programs.antlers-scripts = {
    enable = true;
    plex = {
      backup.enable = true;
      restore.enable = true;
    };
  };

  # Daily backup of Preferences.xml + the Plex databases to the NAS share.
  systemd.services.plex-backup = {
    description = "Back up Plex Preferences.xml and databases to the NAS";
    unitConfig.RequiresMountsFor = "/mnt/backup";
    # On a rebuilt guest, order behind the first-boot restore (a no-op where
    # that unit does not exist).
    after = ["cala-firstboot-plex-restore.service"];
    serviceConfig = {
      Type = "oneshot";
      User = "plex";
      Group = "plex";
      # Refuse to snapshot a server that is unclaimed or has no libraries: that
      # is what a freshly recreated guest looks like before (or if) its restore
      # ran, and plex-backup would otherwise overwrite the share-root
      # Preferences.xml with the unclaimed one and push an empty snapshot to the
      # top of the list — exactly what the next restore attempt would pick up.
      # ExecCondition= skips the run (not a failure) when the check exits 1.
      ExecCondition = pkgs.writeShellScript "plex-backup-sane" ''
        pms="/var/lib/plex/Plex Media Server"
        db="$pms/Plug-in Support/Databases/com.plexapp.plugins.library.db"
        if ! ${pkgs.gnugrep}/bin/grep -q 'PlexOnlineToken="' "$pms/Preferences.xml" 2>/dev/null; then
          echo "plex-backup: server is not claimed (no PlexOnlineToken); refusing to overwrite the backups" >&2
          exit 1
        fi
        sections="$(${pkgs.sqlite}/bin/sqlite3 -readonly "$db" 'select count(*) from library_sections;' 2>/dev/null || echo 0)"
        if [ "''${sections:-0}" -eq 0 ]; then
          echo "plex-backup: library database has no sections (fresh server?); refusing to overwrite the backups" >&2
          exit 1
        fi
      '';
      ExecStart = "${plexBackup}/bin/plex-backup";
    };
  };

  systemd.timers.plex-backup = {
    description = "Daily Plex backup";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
