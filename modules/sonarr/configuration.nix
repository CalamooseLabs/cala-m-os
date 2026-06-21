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

  fileSystems."/mnt/backups/sonarr" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.sonarr}";
    fsType = "nfs";
  };

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
