{
  disko.devices = {
    disk = {
      main = {
        # OS drive = KIOXIA EXCERIA PLUS G4 1TB. Pinned by-id (serial) so disko
        # can NEVER target the WD 2TB data drive, regardless of whether the
        # kernel enumerates this disk as nvme0n1 or nvme1n1 on any given boot.
        # This is the whole disk disko owns; wipeAllDisks=true only touches it.
        device = "/dev/disk/by-id/nvme-KIOXIA-EXCERIA_PLUS_G4_SSD_YEFKF466Z23M";
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
    };
  };
}
