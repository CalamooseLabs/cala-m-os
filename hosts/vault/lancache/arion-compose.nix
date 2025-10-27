{...}: {
  services = {
    lancache = {
      image = "lancachenet/monolithic:latest";
      ports = [
        "80:80"
        "443:443"
      ];
      environment = {
        CACHE_ROOT = "/data/cache";
        CACHE_DISK_SIZE = "1000g";
        CACHE_INDEX_SIZE = "250m";
        CACHE_MAX_AGE = "3650d";
        MIN_FREE_DISK = "10g";
        UPSTREAM_DNS = "8.8.8.8";
        TZ = "America/New_York";
      };
      volumes = [
        "/mnt/cache/lancache:/data/cache"
        "/data/logs:/data/logs"
      ];
    };

    lancache-dns = {
      image = "lancachenet/lancache-dns:latest";
      ports = [
        "53:53/udp"
      ];
      environment = {
        USE_GENERIC_CACHE = "true";
        LANCACHE_IP = "192.168.1.100";
        DNS_BIND_IP = "192.168.1.100";
        UPSTREAM_DNS = "8.8.8.8";
      };
    };
  };
}
