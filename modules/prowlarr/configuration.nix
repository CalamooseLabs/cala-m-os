{
  cala-m-os,
  inputs,
  ...
}: {
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 9696;
        bindaddress = "*";
      };
    };
  };

  boot.supportedFilesystems = ["nfs"];

  # nofail: a missing NAS must not wedge the guest's boot; everything that
  # touches the share waits for it via RequiresMountsFor instead.
  fileSystems."/mnt/backups/prowlarr" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.prowlarr}";
    fsType = "nfs";
    options = ["nofail"];
  };

  # Prowlarr runs under DynamicUser, which implies ProtectSystem=strict: the
  # whole filesystem is read-only to it except its StateDirectory. Its scheduled
  # backups (Settings -> General -> Backups, folder /mnt/backups/prowlarr) can
  # therefore only land on the NAS share if that path is explicitly writable —
  # without this every backup silently fails and prowlarr-restore finds nothing.
  # Mount ordering keeps the app from writing into the empty mountpoint on the
  # local root if the NAS is late.
  systemd.services.prowlarr = {
    serviceConfig.ReadWritePaths = ["/mnt/backups/prowlarr"];
    unitConfig.RequiresMountsFor = ["/mnt/backups/prowlarr"];
  };

  # prowlarr-restore — rebuild state from the newest backup zip on the NAS share
  # (Prowlarr writes its own scheduled backups there). From the antlers scripts
  # collection (the generic arr-restore tool, instantiated for prowlarr).
  # dataDir resolves through systemd's DynamicUser StateDirectory symlink; the
  # script chowns restored files to match the dir's (runtime-allocated) owner.
  programs.antlers-scripts = {
    enable = true;
    arr-restore.instances.prowlarr = {
      port = 9696;
      dataDir = "/var/lib/prowlarr";
      backupDir = "/mnt/backups/prowlarr";
    };
  };
}
