{
  cala-m-os,
  inputs,
  ...
}: {
  imports = [inputs.antlers.nixosModules.antlers-scripts];

  services.radarr = {
    enable = true;
    openFirewall = true;
    settings = {
      update.mechanism = "external";
      server = {
        port = 7878;
        bindaddress = "*";
      };
    };
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/mnt/backups/radarr" = {
    device = "${cala-m-os.nfs.server}:${cala-m-os.nfs.backup.radarr}";
    fsType = "nfs";
  };

  # radarr-restore — rebuild state from the newest backup zip on the NAS share
  # (Radarr writes its own scheduled backups there). From the antlers scripts
  # collection (the generic arr-restore tool, instantiated for radarr).
  programs.antlers-scripts = {
    enable = true;
    arr-restore.instances.radarr = {
      port = 7878;
      dataDir = "/var/lib/radarr/.config/Radarr";
      backupDir = "/mnt/backups/radarr";
    };
  };
}
