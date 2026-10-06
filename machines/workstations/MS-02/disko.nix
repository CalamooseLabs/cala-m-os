{lib, ...}: {
  disko.devices = {
    disk = {
      main = {
        # OS drive = Samsung 990 PRO 2TB, the only disk in this box. Pinned by-id
        # (model+serial) so wipeAllDisks=true / --yes-wipe-all-disks can never
        # target the wrong device under an enumeration-order name like /dev/nvme0n1.
        #
        # Disaster recovery onto a REPLACED drive: the serial no longer matches,
        # so disko would abort before touching anything. Every install step runs
        # --impure, so the installer can hand in the new /dev/disk/by-id/ path:
        #   sudo INSTALL_OS_DISK=/dev/disk/by-id/nvme-<model>_<serial> install-cala-m-os homelab
        # (the variable goes AFTER sudo, or env_reset drops it). A pure rebuild
        # (getEnv = "") always uses the pinned path. disko evaluates this file
        # before the toplevel's by-id assertion can run, so the override is
        # checked here: anything but a /dev/disk/by-id/ path aborts the eval
        # instead of wiping an enumeration-order device.
        # Afterwards, make the new serial the pin here (see wiki/Disaster-Recovery.md).
        device = let
          override = builtins.getEnv "INSTALL_OS_DISK";
        in
          if override == ""
          then "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7L9NJ0L313887A"
          else if lib.hasPrefix "/dev/disk/by-id/" override
          then override
          else throw "INSTALL_OS_DISK must be a /dev/disk/by-id/ path (got: ${override})";
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
