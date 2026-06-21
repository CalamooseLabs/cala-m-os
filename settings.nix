{
  # Globals
  globals = {
    defaultUser = "hub";
    userGroup = "users";
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
    # Lab subnet — homelab / streaming-services (Plex, qBittorrent, *arrs)
    lab = {
      subnet = "10.10.10.0/26";
      prefixLength = 26;
      gateway = "10.10.10.1";
      homelab = "10.10.10.15";
      media = "10.10.10.11";
      torrent = "10.10.10.35";
      vault = "10.10.10.45";
      htpc = "10.10.10.40";
      lanstation-1 = "10.10.10.41";
      lanstation-2 = "10.10.10.42";
      lanstation-3 = "10.10.10.43";
      lanstation-4 = "10.10.10.44";
      battlestation = "10.10.10.30";
    };

    # Studio subnet — live broadcast / OBS + device control (streamdeck, teleprompters)
    studio = {
      subnet = "10.1.10.0/26";
      prefixLength = 26;
      gateway = "10.1.10.1";
      broadcast = "10.1.10.15";
    };
  };

  # NAS NFS Paths
  nfs = {
    server = "nas.calamos.family";
    media = {
      # Shared filesystem root holding both downloads and the library. Mounting
      # this once (instead of per-folder) lets the *arr suite hardlink imports
      # rather than copy across filesystems — see calamoose.hardlinkLayout. The
      # NAS must export this with a Downloads/ dir writable by the qbittorrent uid.
      root = "/mnt/Media Library";
      downloads = "/mnt/Media Library/Downloads";
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
