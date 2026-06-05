{cala-m-os, ...}: {
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
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.backup.sonarr}";
    fsType = "nfs";
  };
}
