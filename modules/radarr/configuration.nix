{cala-m-os, ...}: {
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
}
