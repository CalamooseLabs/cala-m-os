# Single-disk UEFI layout for a Hetzner Cloud CPX instance (ESP + swap + ext4 root).
#
# CPX VMs boot UEFI, so the systemd-boot + ESP layout from hosts/_core works
# as-is (the CX line is legacy BIOS: don't reuse this there). The root disk is
# virtio-SCSI at /dev/sda; its by-id name (scsi-0QEMU_QEMU_HARDDISK_<n>) is
# per-server, so it can't be pinned here. Install with NO Hetzner Volumes
# attached: they also show up as /dev/sdX and could shift the ordering.
#
# Sized for the smallest type (CPX02: 20 GB disk, 1 GB RAM): a 1 GiB swap
# partition backs zram (configuration.nix); the rest is root.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          # x86 bzImage + initrd is ~40 MiB per generation; 5 are kept.
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
          size = "1G";
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
