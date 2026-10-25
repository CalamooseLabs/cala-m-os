# The kexec installer for VIRTUAL machines: ./kexec.nix minus linux-firmware.
#
# A VM's virtio devices need no firmware blobs, and leaving them out roughly
# halves the initrd (the ISO-sized ~1.4 GB image is mostly firmware). That is
# what lets the installer fit a 4 GB cloud box: cala-reinstall holds the initrd
# twice while loading it and refuses when RAM is short. cala-reinstall picks this
# flavour by itself when systemd-detect-virt reports a VM (`--variant full|vm`
# overrides it); it is exposed as `installer-kexec-vm` next to `installer-kexec`.
{lib, ...}: {
  imports = [./kexec.nix];

  # ./kexec.nix re-enables it at mkOverride 60 (netboot-minimal disables at 70).
  hardware.enableRedistributableFirmware = lib.mkOverride 50 false;

  # The installer lives in RAM and then evaluates a whole host flake before it
  # writes anything to /mnt; on a 4 GB VM that peak needs headroom the
  # RAM-only root can't give back. Compressed swap is the only swap there is.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };
}
