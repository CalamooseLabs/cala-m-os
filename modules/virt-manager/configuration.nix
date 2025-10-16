{cala-m-os, ...}: {
  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [cala-m-os.globalDefaultUser];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.runAsRoot = false;
    };
    spiceUSBRedirection.enable = true;
  };
}
