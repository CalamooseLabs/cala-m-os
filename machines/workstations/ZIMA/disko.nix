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
              size = "30G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/persistent";
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
  virtualisation.vmVariantWithDisko.virtualisation.fileSystems."/persistent".neededForBoot = true;
}
