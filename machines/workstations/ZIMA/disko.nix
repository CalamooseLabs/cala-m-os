{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/mmcblk0";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };
            persistent = {
              size = "20G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/persistent";
              };
            };
            root = {
              size = "10G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
              };
            };
            swap = {
              size = "4G";
              content = {
                type = "swap";
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=10G"
          "mode=755"
        ];
      };
    };
  };

  fileSystems."/persistent".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;
}
