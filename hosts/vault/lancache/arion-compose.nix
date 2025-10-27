{...}: {
  project.name = "lancache";

  services = {
    # LANCache Monolithic Container
    lancache = {
      image = "lancachenet/monolithic:latest";
      ports = [
        "80:80"
        "443:443"
      ];
      environment = {
        # Required environment variables ⁽⁸³⁾
        CACHE_ROOT = "/data/cache";
        CACHE_DISK_SIZE = "1000g"; # Adjust based on NFS space
        CACHE_INDEX_SIZE = "250m"; # 250MB per 1TB of cache
        CACHE_MAX_AGE = "3650d"; # ~10 years
        MIN_FREE_DISK = "10g";
        UPSTREAM_DNS = "8.8.8.8";
        TZ = "America/Denver"; # Adjust timezone
      };
      volumes = [
        "/mnt/cache/lancache:/data/cache"
        "/var/log/lancache:/data/logs"
      ];
      restart = "unless-stopped";
    };

    # LANCache DNS Container
    lancache-dns = {
      image = "lancachenet/lancache-dns:latest";
      ports = [
        "53:53/udp"
        "53:53/tcp"
      ];
      environment = {
        # Required environment variables ⁽⁸³⁾
        USE_GENERIC_CACHE = "true";
        LANCACHE_IP = "192.168.1.100"; # MicroVM IP
        DNS_BIND_IP = "0.0.0.0";
        UPSTREAM_DNS = "8.8.8.8";
      };
      restart = "unless-stopped";
    };
  };
}
