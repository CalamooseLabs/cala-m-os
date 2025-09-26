{...}: {
  # cala-m-os,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.impermanence.homeManagerModules.impermanence
  ];

  home.packages = [
    pkgs.usbutils
    pkgs.pciutils
  ];

  # home.persistence."/persistent/home/${cala-m-os.globalDefaultUser}" = {
  #   directories = [
  #     ".gnupg"
  #     ".ssh"
  #     ".local/share/keyrings"
  #   ];
  #   allowOther = true;
  # };
}
