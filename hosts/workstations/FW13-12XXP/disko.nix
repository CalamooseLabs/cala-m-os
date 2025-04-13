{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-id/some-disk-id";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              end = "-70G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            encryptedSwap = {
              size = "10M";
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100;
              };
            };
            plainSwap = {
              size = "100%";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true;
              };
            };
          };
        };
      };
      nodev = {
        "/tmp" = {
          fsType = "tmpfs";
          mountOptions = [
            "size=30G"
          ];
        };
      };
    };
  };
}
