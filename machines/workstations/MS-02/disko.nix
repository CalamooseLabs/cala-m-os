{
  disko.devices = {
    disk = {
      main = {
        # OS drive = Samsung 990 PRO 2TB, the only disk in this box. Pinned by-id
        # (model+serial) so wipeAllDisks=true / --yes-wipe-all-disks can never
        # target the wrong device under an enumeration-order name like /dev/nvme0n1.
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7L9NJ0L313887A";
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
              end = "-8G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            swap = {
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
    };
  };
}
