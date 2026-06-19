{cala-m-os, ...}: {
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
}
