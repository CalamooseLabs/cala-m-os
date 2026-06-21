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

  fileSystems."/mnt/backups/prowlarr" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.prowlarr}";
    fsType = "nfs";
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
