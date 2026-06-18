{
  disko.devices = {
    disk = {
      # Boot Drive
      nvme2 = {
        type = "disk";
        device = "/dev/nvme2n1";
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
                mountOptions = ["defaults"];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = ["defaults" "noatime"];
              };
            };
          };
        };
      };

      nvme0 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            mdadm = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "vm-data";
              };
            };
          };
        };
      };

      nvme1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            mdadm = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "vm-data";
              };
            };
          };
        };
      };
    };

    # mdadm RAID 0 Array Configuration
    mdadm = {
      vm-data = {
        type = "mdadm";
        level = 0; # RAID 0 (striping)
        content = {
          type = "filesystem";
          format = "xfs"; # XFS for best performance
          mountpoint = "/vm-data";
          mountOptions = [
            "defaults"
            "noatime"
            "nodiratime"
          ];
        };
      };
    };
  };
}
