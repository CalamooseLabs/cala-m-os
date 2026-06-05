{cala-m-os, ...}: {
  services.plex = {
    enable = true;
    openFirewall = true;
  };

  boot.supportedFilesystems = ["nfs"];

  fileSystems."/media/movies" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.media.movies}";
    fsType = "nfs";
  };

  fileSystems."/media/tv-shows" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.media.tv-shows}";
    fsType = "nfs";
  };

  fileSystems."/mnt/backup" = {
    device = "${cala-m-os.nfs.server}${cala-m-os.nfs.backup.plex}";
    fsType = "nfs";
  };
}
