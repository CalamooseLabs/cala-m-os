# The installer ISO (USB stick, or a cloud provider's virtual CD-ROM).
{modulesPath, ...}: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./installer.nix
  ];

  isoImage = {
    squashfsCompression = "lz4";
    forceTextMode = true;
  };
}
