{
  cala-m-os,
  pkgs,
  ...
}: let
  # plex-backup — scheduled snapshot of identity + databases to the NAS.
  plexBackup = pkgs.writeShellApplication {
    name = "plex-backup";
    runtimeInputs = with pkgs; [coreutils findutils util-linux sqlite];
    text = builtins.readFile ./backup.sh;
  };

  # plex-restore — rebuild server state from the NAS backup share.
  plexRestore = pkgs.writeShellApplication {
    name = "plex-restore";
    runtimeInputs = with pkgs; [coreutils findutils util-linux systemd curl gnugrep];
    text = builtins.readFile ./restore.sh;
  };
in {
  services.plex = {
    enable = true;
    openFirewall = true;
  };

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

  # Admin tooling: snapshot the server, and restore it after a rebuild.
  environment.systemPackages = [plexBackup plexRestore];

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
