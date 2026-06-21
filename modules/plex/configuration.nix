{
  cala-m-os,
  inputs,
  pkgs,
  ...
}: let
  # plex-backup/plex-restore now ship from the antlers scripts collection. The
  # script defaults (data dir /var/lib/plex, backup /mnt/backup, plex:plex,
  # plex.service, :32400, retention 7) match this host, so no overrides needed.
  plexBackup = inputs.antlers.packages.${pkgs.system}.plex-backup;
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

  fileSystems."/mnt/backup" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.plex}";
    fsType = "nfs";
  };

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
    serviceConfig = {
      Type = "oneshot";
      User = "plex";
      Group = "plex";
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
