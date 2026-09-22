# Single-disk UEFI layout for a Hetzner Cloud instance (ESP + swap + ext4 root).
#
# Cloud instances are DISPOSABLE and world backups are on, so one disk is fine.
# The disk is a single virtio-SCSI device at /dev/sda (NOT NVMe — that's the
# Robot/AX bare-metal line). New Cloud x86 VMs boot UEFI, so the systemd-boot +
# ESP layout from hosts/_core works as-is.
#
# TODO: confirm the device from the rescue system (`lsblk`); it is normally
# /dev/sda. nixos-anywhere partitions THIS device; a wrong name wipes the wrong
# disk.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
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
