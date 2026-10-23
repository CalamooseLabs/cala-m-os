# Single-disk UEFI layout for a Hetzner Cloud CAX instance (ESP + ext4 root).
#
# CAX VMs always boot UEFI, so the systemd-boot + ESP layout from hosts/_core
# works as-is. The root disk is virtio-SCSI at /dev/sda; its by-id name
# (scsi-0QEMU_QEMU_HARDDISK_<n>) is per-server, so it can't be pinned here.
# Install with NO Hetzner Volumes attached: they also show up as /dev/sdX and
# could shift the ordering. No swap partition: zram covers it (configuration.nix).
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          # aarch64 boots the UNCOMPRESSED kernel Image (~61 MiB, vs ~15 MiB
          # bzImage on x86), so ~90 MiB per generation with its initrd.
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
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
