{
  # Globals
  globals = {
    defaultUser = "hub";
    adminGroup = "wheel";
    defaultEmail = "it@calamos.family";
    fullName = "Cole J. Calamos";
    TZ = "America/Denver";
  };

  # Lab Settings
  fqdn = "calamooselabs.com";
  networking = {
    prefixLength = "26";
    network-name = "10-macvtap";
  };

  # IP Address Table
  ip = {
    gateway = "10.10.10.1";
    lab = "10.10.10.15";
    media = "10.10.10.10";
    torrent = "10.10.10.35";
    vault = "10.10.10.45";
    htpc = "10.10.10.40";
    lanstation-1 = "10.10.10.41";
    lanstation-2 = "10.10.10.42";
    lanstation-3 = "10.10.10.43";
    lanstation-4 = "10.10.10.44";
    studio = "10.10.10.30";
  };

  # NAS NFS Paths
  nfs = {
    server = "nas.calamos.family";
    media = {
      movies = "/mnt/Media Library/Movies";
      tv-shows = "/mnt/Media Library/TV-Shows";
      lancache = "/mnt/Media Library/Cache";
    };
    backup = {
      plex = "/mnt/Media Library/Backups/Plex";
      radarr = "/mnt/Media Library/Backups/Radarr";
      sonarr = "/mnt/Media Library/Backups/Sonarr";
      prowlarr = "/mnt/Media Library/Backups/Prowlarr";
    };
  };
}
