# Single-NVMe UEFI layout for a Hetzner dedicated box (ESP + swap + ext4 root).
#
# Instances are DISPOSABLE and world backups are on, so a single disk is an
# acceptable trade for simplicity. For uptime-through-disk-loss on a 2-NVMe AX
# box, the disko boot-raid1 example (mdadm RAID1, ESP metadata=1.0, GRUB
# mirroredBoots for real ESP redundancy) is the alternative — swap this file for
# it if the box has two drives and downtime matters.
#
# TODO: confirm the real device from the rescue system (`lsblk`). nixos-anywhere
# partitions THIS device; a wrong name wipes the wrong disk.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
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
            mountOptions = ["umask=0077"];
          };
        };
        swap = {
          size = "8G";
          content = {
            type = "swap";
            discardPolicy = "both";
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
