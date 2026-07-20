{
  # Disks are pinned by /dev/disk/by-id/ (model+serial), NOT /dev/nvmeXn1.
  # NVMe enumeration order is not stable across boots, so name-based targeting
  # let disko format ESP/root onto whatever disk happened to be "nvme2n1" at
  # install time — which then mismatched the bootloader on the next boot
  # ("Switch root target contains no usable init"). by-id makes the physical
  # role of each disk deterministic. The disk keys below (boot/recordings0/1)
  # only set the partlabels (disk-<key>-<part>); the by-id `device` is what
  # actually binds a role to a physical drive.
  disko.devices = {
    disk = {
      # Boot Drive — Samsung 990 EVO Plus (serial S7U5NJ0Y201623).
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_1TB_S7U5NJ0Y201623A";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              # 1G (was 512M): NVIDIA initrds are large and broadcast keeps a few
              # generations — 512M ESPs are a classic "No space left on /boot".
              size = "1G";
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

      # RAID0 "recordings" member — Samsung 9100 PRO (PCIe5, serial S7YENJ0Y305813).
      recordings0 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_9100_PRO_1TB_S7YENJ0Y305813L";
        content = {
          type = "gpt";
          partitions = {
            mdadm = {
              size = "100%";
              type = "FD00"; # Linux RAID — so out-of-band tools flag the member
              content = {
                type = "mdraid";
                name = "recordings";
              };
            };
          };
        };
      };

      # RAID0 "recordings" member — Sabrent SB-RKT5 (PCIe5, serial 48869585500017).
      recordings1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Sabrent_SB-RKT5-1TB_48869585500017";
        content = {
          type = "gpt";
          partitions = {
            mdadm = {
              size = "100%";
              type = "FD00"; # Linux RAID — so out-of-band tools flag the member
              content = {
                type = "mdraid";
                name = "recordings";
              };
            };
          };
        };
      };
    };

    # mdadm RAID 0 Array Configuration
    mdadm = {
      recordings = {
        type = "mdadm";
        level = 0; # RAID 0 (striping)
        content = {
          type = "filesystem";
          format = "xfs"; # XFS for best performance
          mountpoint = "/recordings";
          mountOptions = [
            "defaults"
            "noatime"
            "nodiratime"
            # RAID0 has zero redundancy and disko emits this as a REQUIRED mount;
            # nofail keeps a missing/late/failed member from wedging boot at
            # emergency.target (this data array must never block reaching login).
            "nofail"
            "x-systemd.device-timeout=30s"
          ];
        };
      };
    };
  };
}
