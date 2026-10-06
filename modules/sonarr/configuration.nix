{
  cala-m-os,
  inputs,
  ...
}: {
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  services.sonarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 8989;
        bindaddress = "*";
      };
    };
  };

  boot.supportedFilesystems = ["nfs"];

  # nofail: a missing NAS must not wedge the guest's boot; everything that
  # touches the share waits for it via RequiresMountsFor instead.
  fileSystems."/mnt/backups/sonarr" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.sonarr}";
    fsType = "nfs";
    options = ["nofail"];
  };

  # Sonarr's scheduled backups (Settings -> General -> Backups) target
  # /mnt/backups/sonarr; never let it start with the share unmounted, or it
  # writes them into the empty mountpoint on the local root instead.
  systemd.services.sonarr.unitConfig.RequiresMountsFor = ["/mnt/backups/sonarr"];

  # The nixpkgs sonarr module only declares StateDirectory=sonarr; Sonarr itself
  # creates .config/NzbDrone a few seconds after its first start. The first-boot
  # sonarr-restore is ordered After=sonarr.service, which for a Type=simple unit
  # only means "started", so on a fresh root it could run before the data dir
  # exists and abort ("data dir does not exist"). Pre-create it, as the radarr
  # module does via tmpfiles, so the restore is deterministic.
  systemd.tmpfiles.rules = [
    "d /var/lib/sonarr 0755 sonarr sonarr - -"
    "d /var/lib/sonarr/.config 0750 sonarr sonarr - -"
    "d /var/lib/sonarr/.config/NzbDrone 0700 sonarr sonarr - -"
  ];

  # sonarr-restore — rebuild state from the newest backup zip on the NAS share
  # (Sonarr writes its own scheduled backups there). From the antlers scripts
  # collection (the generic arr-restore tool, instantiated for sonarr).
  programs.antlers-scripts = {
    enable = true;
    arr-restore.instances.sonarr = {
      port = 8989;
      dataDir = "/var/lib/sonarr/.config/NzbDrone";
      backupDir = "/mnt/backups/sonarr";
    };
  };
}
