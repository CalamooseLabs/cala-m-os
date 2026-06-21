{
  inputs,
  pkgs,
  modulesPath,
  lib,
  ...
}: {
  imports = [(modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  # Enable SSH in the boot process.
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce ["multi-user.target"];
  users.users.root.openssh.authorizedKeys.keyFiles = [
    ./public_keys/id_ed25519_sk.pub
    ./public_keys/backup_id_ed25519_sk.pub
  ];

  networking.hostName = lib.mkForce "cala-m-os-installer";

  programs.bash.enableCompletion = true;

  environment.systemPackages = with pkgs; [
    disko
    git
    neovim
    # install-cala-m-os (the 5-step installer) + its bash-completion now ship
    # together from the antlers scripts collection. disko stays on PATH above so
    # the installer's Step One resolves it offline. Defaults (flake ref, clone
    # URL, version attr, /mnt + /etc/nixos paths, hub/root passwords) match this
    # ISO, so no overrides are needed.
    inputs.antlers.packages.${pkgs.stdenv.hostPlatform.system}.install-cala-m-os
  ];

  services.pcscd.enable = true;

  isoImage = {
    squashfsCompression = "lz4";
    forceTextMode = true;
  };
}
